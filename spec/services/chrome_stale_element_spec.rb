require "rails_helper"

RSpec.describe ChromeStaleElement do
  let(:bridge) do
    Class.new do
      prepend ChromeStaleElement

      def execute(error)
        raise error
      end
    end.new
  end

  it "lets Capybara refind a detached node reported incorrectly by ChromeDriver" do
    error = Selenium::WebDriver::Error::UnknownError.new('unhandled inspector error: {"code":-32000,"message":"Node with given id does not belong to the document"}')
    expect { bridge.send(:execute, error) }.to raise_error(Selenium::WebDriver::Error::StaleElementReferenceError)
  end

  it "preserves unrelated driver errors" do
    error = Selenium::WebDriver::Error::UnknownError.new("Chrome has crashed")
    expect { bridge.send(:execute, error) }.to raise_error(error)
  end
end
