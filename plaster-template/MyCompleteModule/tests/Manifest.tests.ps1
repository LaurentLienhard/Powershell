$ModuleName = "<%= $PLASTER_PARAM_ModuleName %>"

$here = (Split-Path -Parent $MyInvocation.MyCommand.Path).Replace('tests', '')

$modulePath = Join-Path -Path $here -ChildPath \
$moduleName = (Get-Item -Path "$here\*.psd1").BaseName
$moduleManifest = Join-Path -Path $modulePath -ChildPath "$ModuleName.psd1"

$scriptsModules = Get-ChildItem $here\public -Include *.psd1, *.psm1, *.ps1 -Exclude *.tests.ps1 -Recurse

Import-Module $ModuleName

Describe 'Module' {
	Context 'Manifest' {
		$script:manifest = $null

		It 'has a valid manifest' {
			{
				$script:manifest = Test-ModuleManifest -Path $moduleManifest -ErrorAction Stop -WarningAction SilentlyContinue
			} | Should Not throw
		}
		
		It 'has a valid name in the manifest' {
			$script:manifest.Name | Should Be $moduleName
		}

		It 'has a valid root module' {
			$script:manifest.RootModule | Should Be ($moduleName + ".psm1")
		}

		It 'has a valid version in the manifest' {
			$script:manifest.Version -as [Version] | Should Not BeNullOrEmpty
		}
	
		It 'has a valid description' {
			$script:manifest.Description | Should Not BeNullOrEmpty
		}

		It 'has a valid author' {
			$script:manifest.Author | Should Not BeNullOrEmpty
		}
	
		It 'has a valid guid' {
			{ 
				[guid]::Parse($script:manifest.Guid) 
			} | Should Not throw
		}
	
		It 'has a valid copyright' {
			$script:manifest.CopyRight | Should Not BeNullOrEmpty
		}
	}
}

Describe 'General - Testing all scripts and modules against the Script Analyzer Rules' {

    Context "Checking files to test exist and Invoke-ScriptAnalyzer cmdLet is available" {

        It "Checking files exist to test." {

            $scriptsModules.count | Should Not Be 0

        }

        It "Checking Invoke-ScriptAnalyzer exists." {

            { Get-Command Invoke-ScriptAnalyzer -ErrorAction Stop } | Should Not Throw

        }

    }


	forEach ($scriptModule in $scriptsModules) {
	
		switch -wildCard ($scriptModule) { 
	
			'*.psm1' { $typeTesting = 'Module' } 
	
			'*.ps1' { $typeTesting = 'Script' } 
	
			'*.psd1' { $typeTesting = 'Manifest' } 
	
		}
		Context "Checking $typeTesting - $scriptmodule - conform to Script Anaylzer Rule" {
		$scriptAnalyzerRules = Get-ScriptAnalyzerRule
		foreach ($scriptAnalyzerRule in $scriptAnalyzerRules) {
			It "Script Analyser Rule $scriptAnalyzerRule " {
				(Invoke-ScriptAnalyzer -Path $scriptModule -IncludeRule $scriptAnalyzerRule).count | Should Be 0
			}
		}
	}
}
	
	

	
}