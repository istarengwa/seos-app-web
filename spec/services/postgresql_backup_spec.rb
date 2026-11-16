require "rails_helper"
require "tmpdir"

if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
  RSpec.describe "Sauvegarde PostgreSQL" do
    it "exporte une vraie archive et ses fichiers, prépare une restauration et détecte une altération" do
      Dir.mktmpdir do |root|
        storage = File.join(root, "storage")
        FileUtils.mkdir_p(storage)
        File.write(File.join(storage, "piece.txt"), "Pièce jointe PostgreSQL")
        backup = File.join(root, "backup")
        restored = File.join(root, "restored")
        config = ActiveRecord::Base.connection_db_config.configuration_hash

        SeosBackup.create_postgresql!(databases: { primary: config }, storage: storage, destination: backup)
        expect(File.size(File.join(backup, "primary.dump"))).to be > 0
        expect(SeosBackup.verify!(backup)).to be(true)
        SeosBackup.restore!(source: backup, destination: restored)
        expect(File.read(File.join(restored, "storage/piece.txt"))).to eq("Pièce jointe PostgreSQL")
        expect { SeosBackup.create_postgresql!(databases: { primary: config }, storage: storage, destination: backup) }.to raise_error(ArgumentError)
        File.write(File.join(backup, "primary.dump"), "Archive altérée")
        expect { SeosBackup.verify!(backup) }.to raise_error(RuntimeError, /altérée/)
      end
    end
  end
end
