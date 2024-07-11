function New-Password {
    param (
        [Int32]$Amount = 1,
        #[Int32]$MaxLength = 16, #missing
        [Int32]$WordCount = 2,
        [switch]$Symbols, 
        [switch]$Numbers,
        [switch]$Explanation,
        [switch]$Conjunctions,
        [switch]$RandomCaps

    )
    begin {
        # building wordlist
        $Wordlistpath = "$env:USERPROFILE\Documents\dictionary.csv"
        if (test-path $Wordlistpath) {
            $words = Import-Clixml $Wordlistpath 
        }
        else {
            $words = (invoke-restmethod 'https://www.bragitoff.com/wp-content/uploads/2016/03/dictionary.csv' | ConvertFrom-Csv -Header 'Word', 'Wordclass', 'Explanation')
            $words | Export-clixml $Wordlistpath 
        }


        $conjunction = "the", "my", "we", "our", "and", "but", "for", "so", "yet", "or", "after", "when"
        $SymbolList = @('!', '#', '$', '%', '&', '(', ')', '*', '+', ',', '.', ':', ';', '=', '?', '@')
        $WordCounter = 0
        $PasswordCounter = 0
        $PasswordList = New-Object -TypeName System.Collections.ArrayList
        
    }
    process {
        while ($PasswordCounter -lt $amount) {
            $CapsCounter = 0
            $WordCounter = 0
            $string = ''
            $WordArray = New-Object -TypeName System.Collections.ArrayList
            $randnum = get-random -Minimum 10 -Maximum 99
            $randomsymbol = $SymbolList[(get-random -Minimum 0 -maximum ($SymbolList.count - 1))]
        
            # word count
            while ($WordCounter -lt $WordCount) {
                $word = ($words[(get-random -Minimum 0 -maximum ($words.count - 1))])
                [void]$WordArray.Add($word)
                $WordCounter ++
            }
            foreach ($word in $WordArray) {
                $con = $conjunction[(get-random -Minimum 0 -Maximum($conjunction.Count - 1))]
                $contitlecase = (Get-UICulture).TextInfo.ToTitleCase($con)
                if ($string -eq '') {
                    $string = ($word.word).replace(' ', '')
                }
                else {
                    if ($Conjunctions) {
                        $string = $string + $contitlecase + ($word.word).replace(' ', '')
                    }
                    else {
                        $string = $string + ($word.word).replace(' ', '')
                    }
                }
            }
            # explanation
            if ($Explanation) {
                $WordArray
                "`n"
            }
            # randomcaps
            if ($randomcaps) {
                $chararray = $string.ToCharArray()
                $RandomCapsAmount = Get-Random -Minimum 0 -Maximum ($string.length)
                while ($CapsCounter -lt $RandomCapsAmount) {
                    $randomnum = get-random -minimum 0 -maximum ($chararray.count - 1)
                    if ($chararray[$randomnum] -cmatch '[a-z]') {
                        $chararray[$randomnum] = $chararray[$randomnum].ToString().ToUpper()
                        $CapsCounter ++
                    }
                }
                $string = [System.String]::new($chararray)
            }

            # symbols
            if ($Symbols) {
                $string = $string + $randomsymbol
            }
            # numbers
            if ($Numbers) {
                $string = $string + $randnum
            }
            [void]$PasswordList.add($string)
            $PasswordCounter ++
        }
        $PasswordList
    }
}