require 'rubygems'
require 'selenium-webdriver'

driver = Selenium::WebDriver.for :chrome

driver.get "http://www.mobizen.com/home#!home"

def login
  email = driver["user-email"]
  password = driver["user-pw"]
  submit = driver["signin-button"]

  email.send_keys("eric.d.wishart@gmail.com")
  password.send_keys("cutevomit4")
  submit.click
end

screen = driver["rswp"]
width = screen["width"]
height = screen["height"]

ss = driver.screenshot_as(:png)




driver.get("http://www.google.com");
WebElement ele = driver.findElement(By.id("hplogo"));   
//Get entire page screenshot
File screenshot = ((TakesScreenshot)driver).getScreenshotAs(OutputType.FILE);
BufferedImage  fullImg = ImageIO.read(screenshot);
//Get the location of element on the page
Point point = ele.getLocation();
//Get width and height of the element
int eleWidth = ele.getSize().getWidth();
int eleHeight = ele.getSize().getHeight();
//Crop the entire page screenshot to get only element screenshot
BufferedImage eleScreenshot= fullImg.getSubimage(point.getX(), point.getY(), eleWidth,
    eleHeight);
ImageIO.write(eleScreenshot, "png", screenshot);
//Copy the element screenshot to disk
File screenshotLocation = new File("C:\\images\\GoogleLogo_screenshot.png");
FileUtils.copyFile(screen, screenshotLocation);


driver.save_screenshot("./screen.png")
