# ChromeDriver 151 sometimes reports detached DOM nodes as an unknown error.
# Translate only that response so Capybara can use its normal refind/wait logic.
module ChromeStaleElement
  private

  def execute(...)
    super
  rescue Selenium::WebDriver::Error::UnknownError => error
    raise unless error.message.include?("Node with given id does not belong to the document")

    raise Selenium::WebDriver::Error::StaleElementReferenceError, error.message
  end
end

Selenium::WebDriver::Remote::Bridge.prepend(ChromeStaleElement)
