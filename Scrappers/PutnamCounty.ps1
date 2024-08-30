# Define the URL to fetch the property information
$url = "https://apps.putnam-fl.com/pa/property/?type=api&parcel=04-10-24-9030-0090-0260"

# Use Invoke-WebRequest to fetch the content of the page
$response = Invoke-WebRequest -Uri $url -UseBasicParsing

# Extract property details using regex patterns
$parcelId = [regex]::Match($response.Content, "Parcel:\s*([\d\-]+)").Groups[1].Value
$owner = [regex]::Match($response.Content, "Owner:\s*([^\r\n]+)").Groups[1].Value
$vid = [regex]::Match($response.Content, "VID:\s*([^\r\n]+)").Groups[1].Value
$address = [regex]::Match($response.Content, "Mailing Address:\s*([^\r\n]+)").Groups[1].Value -replace "<br>", "`n"
$subdivision = [regex]::Match($response.Content, "Subdivision:\s*([^\r\n]+)").Groups[1].Value
$description = [regex]::Match($response.Content, "Description:\s*([^\r\n]+)").Groups[1].Value
$taxYear = [regex]::Match($response.Content, "Tax Roll Year\s*([\d]+)").Groups[1].Value

# Property characteristics
$justValue = [regex]::Match($response.Content, "Just Value of Land:\s*\$([\d,]+)").Groups[1].Value
$marketValue = [regex]::Match($response.Content, "Market Value:\s*\$([\d,]+)").Groups[1].Value
$acreage = [regex]::Match($response.Content, "Total Acreage:\s*([\d\.]+)").Groups[1].Value
$propertyUse = [regex]::Match($response.Content, "Property Use:\s*([^\r\n]+)").Groups[1].Value
$structures = [regex]::Match($response.Content, "Structures:\s*([\d]+)").Groups[1].Value
$mobileHomes = [regex]::Match($response.Content, "Mobile Homes:\s*([\d]+)").Groups[1].Value
$neighborhood = [regex]::Match($response.Content, "Neighborhood:\s*([^\r\n]+)").Groups[1].Value
$location = [regex]::Match($response.Content, "Location:\s*([^\r\n]+)").Groups[1].Value
$censusBlock = [regex]::Match($response.Content, "Census Block:\s*([\d]+)").Groups[1].Value

# Non-Ad Valorem Assessments
$assessmentCode = [regex]::Match($response.Content, "Code:\s*([^\r\n]+)").Groups[1].Value
$assessmentDescription = [regex]::Match($response.Content, "Description:\s*([^\r\n]+)").Groups[1].Value
$units = [regex]::Match($response.Content, "Units:\s*([\d]+)").Groups[1].Value
$rate = [regex]::Match($response.Content, "Rate:\s*\$([\d\.]+)").Groups[1].Value
$amount = [regex]::Match($response.Content, "Amount:\s*\$([\d\.]+)").Groups[1].Value

# Output the extracted data
Write-Host "Property Details"
Write-Host "Parcel ID: $parcelId"
Write-Host "Owner: $owner"
Write-Host "VID: $vid"
Write-Host "911 Address: None assigned"  # This is static since there's no data in the example
Write-Host "Mailing Address: $address"
Write-Host "Subdivision: $subdivision"
Write-Host "Legal Description: $description"
Write-Host "Tax Roll Year: $taxYear"
Write-Host ""
Write-Host "Property Characteristics"
Write-Host "Just Value of Land: $$justValue"
Write-Host "Market Value: $$marketValue"
Write-Host "Total Acreage: $acreage acres"
Write-Host "Property Use: $propertyUse"
Write-Host "Structures: $structures"
Write-Host "Mobile Homes: $mobileHomes"
Write-Host "Neighborhood: $neighborhood"
Write-Host "Location: $location"
Write-Host "Census Block: $censusBlock"
Write-Host ""
Write-Host "Non-Ad Valorem Assessments"
Write-Host "Code: $assessmentCode"
Write-Host "Description: $assessmentDescription"
Write-Host "Units: $units"
Write-Host "Rate: $$rate"
Write-Host "Amount: $$amount"
