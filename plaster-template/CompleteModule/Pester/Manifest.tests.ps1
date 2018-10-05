$ModuleName = "<%= $PLASTER_PARAM_ModuleName %>"

$here = (Split-Path -Parent $MyInvocation.MyCommand.Path).Replace('Pester', '')

$modulePath = Join-Path -Path $here -ChildPath \
$moduleName = (Get-Item -Path "$here\*.psd1").BaseName
$moduleManifest = Join-Path -Path $modulePath -ChildPath "$ModuleName.psd1"

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