# Inspired by https://github.com/Huachao/vscode-restclient/issues/563


# Uncomment and edit the jsonFilePath parameter below based on your needs.
# TODO: Add support for command line parameter and batch processing...

#$jsonFilePath = "C:\temp\postman backup\94d30efb-03c3-47e0-be4c-0cb110aab381.json"

$jsonContent = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json

$baseFileName = "$($jsonContent.info.name).rest".replace(" ", "_")

$outputFilePath = Join-Path (Get-Item $jsonFilePath).Directory "$baseFileName"

$output = @()

function Format-RequestBlock($request) {

	# Not the actual request item yet, keep going
	if ($request.item -ne $null) {
		foreach ($internalItem in $request.item) {

			$formattedRequest = Format-RequestBlock -request $internalItem
			$output += $formattedRequest
		}
	}
	else {
		
		$output  = "###`n"
		$output += "# $($request.name)`n"
		$output += "###`n"

		#url formatting in case of nasty variables like :param
		$url = $request.request.method + " " + $request.request.url.raw + "`n"
		foreach ($urlVariable in $request.request.url.variable) {
			$url = $url.replace(":$($urlVariable.key)", $urlVariable.value)
		}
		$output += $url

		#query parameters
		$firstQueryParameter = $true
		$comment = "#"
		foreach ($qparam in $request.request.url.query) {
			if($qparam.disabled -eq $true) {
				$comment = "#"
			} else {
				$comment = ""
			}
			if($firstQueryParameter -eq $true) {
				$output += "$($comment)?$($qparam.key)=$($qparam.value)`n"
				$firstQueryParameter = $false
			} else {
				$output += "$($comment)&$($qparam.key)=$($qparam.value)`n"
			}
		}

		#headers
		foreach ($header in $request.request.header) {
			$output += "$($header.key): $($header.value)`n"
		}

		if($request.request.body -ne $null) {
			$output += "Content-Type: application/$($request.request.body.options.raw.language)`n"
			$output += "`n$($request.request.body.raw)`n"			
		}
		$output += "`n"
	}
	
	
	return $output
}

foreach ($variable in $jsonContent.variable) {	
	$output += "@$($variable.key) = $($variable.value)`n"
}


# Drill down item hierarchy
foreach ($item in $jsonContent.item) {	
	$output += Format-RequestBlock -request $item
}

$output | Out-File -FilePath $outputFilePath