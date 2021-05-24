Task IntegrationTest {
    "`n`tSTATUS: Testing with PowerShell $PSVersion"
    # Run Script Analyzer
    $start = Get-Date

    $scriptAnalyerResults = Invoke-ScriptAnalyzer -Path (Join-Path -Path $env:BHProjectPath -ChildPath $env:BHProjectName) -Recurse -Severity Error -ErrorAction SilentlyContinue
    $end = Get-Date
    $duration = ($end - $start).TotalMilliSeconds
    

    # Gather test results. Store them in a variable and file
    $testFileName = "IntegrationTestResults.xml"
    $testResultPath = "$(property BHBuildOutput)\Pester"

    if (-not (Test-Path -Path $testResultPath)) {
        mkdir -Path $testResultPath -ErrorAction SilentlyContinue | Out-Null
    }
    
    $testResults = Invoke-Pester -Path "$(property BHPSModulePath)\Tests\Integration" -PassThru -OutputFormat NUnitXml -OutputFile "$(property BHBuildOutput)\Pester\$testFileName"

    assert ($testResults.FailedCount -eq 0)
    if ($testResults.FailedCount -gt 0) {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"      
    }
    "`n"
}