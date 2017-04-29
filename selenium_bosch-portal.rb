require 'rubygems'
require "selenium-webdriver"

class DriveIt
  def initialize(host="http://localhost:3001")

    @host = host
    @driver = Selenium::WebDriver.for :chrome
    @driver.navigate.to "http://localhost:3001"

  end

  def driver
    @driver
  end

  def save_screenshot
    time = Time.now.strftime("%Y-%m-%d_%H_%M_%S.%3N")
    @driver.save_screenshot("#{time}_shot.png")
  end

  def login
    account_email 'user@user.com'
    account_password 'yagni123'
    submit
  end

  def account_email(email)
    e = @driver.find_element(:id, 'account_email')
    e.send_keys email
  end

  def account_password(password)
    e = @driver.find_element(:id, 'account_password')
    e.send_keys password
  end

  def submit
    e = @driver.find_element(:name, 'commit')
    e.click
  end

  def save_page
    time = Time.now.strftime("%Y-%m-%d_%H_%M_%S.%3N")
    File.open("#{time}.html",'w'){|f| f.write @driver.page_source}
  end
end

d = DriveIt.new
d.login
d.save_screenshot

#sleep 5
#driver.quit
