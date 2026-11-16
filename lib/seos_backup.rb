require "sqlite3"
require "fileutils"
require "digest"
require "json"
require "open3"
module SeosBackup
  def self.create_postgresql!(databases:, storage:, destination:)
    raise ArgumentError, "Destination déjà existante" if File.exist?(destination)
    FileUtils.mkdir_p(destination, mode: 0o700)
    databases.each do |name, config|
      raise ArgumentError, "Nom de base invalide" unless name.to_s.match?(/\A[a-z_]+\z/)
      raise ArgumentError, "Base PostgreSQL requise" unless config.fetch(:adapter) == "postgresql"
      environment = {
        "PGHOST" => config[:host].to_s, "PGPORT" => config[:port].to_s,
        "PGUSER" => config[:username].to_s, "PGPASSWORD" => config[:password].to_s
      }
      run!(environment, "pg_dump", "--format=custom", "--file", File.join(destination, "#{name}.dump"), "--dbname", config.fetch(:database))
    end
    File.write(File.join(destination, "postgresql.json"), JSON.pretty_generate(databases.keys.map(&:to_s)))
    finish!(storage: storage, destination: destination)
  end

  # Run with application writers and workers stopped: database and files form one snapshot.
  def self.create!(database:, storage:, destination:)
    raise ArgumentError, "Destination déjà existante" if File.exist?(destination)
    FileUtils.mkdir_p(destination, mode: 0o700)
    source = SQLite3::Database.new(database, readonly: true)
    target = SQLite3::Database.new(File.join(destination, "primary.sqlite3"))
    backup = SQLite3::Backup.new(target, "main", source, "main")
    begin
      result = backup.step(-1)
      raise "Sauvegarde SQLite incomplète" unless result == SQLite3::Constants::ErrorCode::DONE
    ensure
      backup.finish
      target.close
      source.close
    end
    finish!(storage: storage, destination: destination)
  end
  def self.finish!(storage:, destination:)
    FileUtils.cp_r(storage, File.join(destination, "storage")) if File.directory?(storage)
    manifest = Dir.glob(File.join(destination, "**", "*"), File::FNM_DOTMATCH).select { |file| File.file?(file) }.to_h do |file|
      [ file.delete_prefix("#{destination}/"), Digest::SHA256.file(file).hexdigest ]
    end
    File.write(File.join(destination, "manifest.json"), JSON.pretty_generate(manifest), mode: "w", perm: 0o600)
    verify!(destination)
  end
  def self.verify!(directory)
    manifest = JSON.parse(File.read(File.join(directory, "manifest.json")))
    manifest.each do |relative, hash|
      raise "Chemin de sauvegarde invalide" if relative.start_with?("/") || relative.split("/").include?("..")
      file = File.join(directory, relative)
      raise "Sauvegarde altérée : #{relative}" unless File.file?(file) && Digest::SHA256.file(file).hexdigest == hash
    end
    if File.exist?(File.join(directory, "postgresql.json"))
      JSON.parse(File.read(File.join(directory, "postgresql.json"))).each do |name|
        raise "Nom de base invalide" unless name.match?(/\A[a-z_]+\z/)
        run!({}, "pg_restore", "--list", File.join(directory, "#{name}.dump"))
      end
      return true
    end
    database = SQLite3::Database.new(File.join(directory, "primary.sqlite3"), readonly: true)
    begin
      raise "Intégrité SQLite invalide" unless database.get_first_value("PRAGMA integrity_check") == "ok"
      raise "Clés étrangères invalides" unless database.execute("PRAGMA foreign_key_check").empty?
    ensure
      database.close
    end
    true
  end
  def self.restore!(source:, destination:)
    raise ArgumentError, "La restauration exige un répertoire neuf" if File.exist?(destination)
    verify!(source)
    FileUtils.mkdir_p(destination, mode: 0o700)
    FileUtils.cp_r(Dir.glob(File.join(source, "*")), destination)
    verify!(destination)
  end

  def self.run!(environment, *command)
    _output, error, status = Open3.capture3(environment, *command)
    raise "Échec #{command.first} : #{error}" unless status.success?
  end
  private_class_method :finish!, :run!
end
