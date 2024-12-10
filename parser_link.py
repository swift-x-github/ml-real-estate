import requests
from bs4 import BeautifulSoup
import pandas as pd
import time

# Base URL for the pages to scrape
base_url = "https://restproperty.com/filter/?type-search=44&rooms=&type-country=1&reginput[0]=47&price1=&price2=&objectid=&area-from=&area-to=&etag-from=&etag-to=&year-from=&year-to=&sea-from=&sea-to=&aero=&elcount=48&PAGEN_1="

all_links = []

# Loop through pages (1 to 52)
for page in range(1, 53):
    url = base_url + str(page)
    response = requests.get(url)
    soup = BeautifulSoup(response.content, 'html.parser')
    
    # Assuming that apartment links have the class 'link-detail-apart', adjust this if necessary
    links = soup.find_all('a', class_='link-detail-apart')
    
    for link in links:
        href = link.get('href')
        if href:
            all_links.append(href)
    
    # Delay of 1 second between requests to avoid overloading the server
    time.sleep(1)

# Save the links to a CSV file
df = pd.DataFrame(all_links, columns=['Link'])
df.to_csv('apartment_links.csv', index=False)

print("Links saved to apartment_links.csv")
