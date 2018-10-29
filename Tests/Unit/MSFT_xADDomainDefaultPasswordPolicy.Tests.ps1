[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

$Global:DSCModuleName      = 'xActiveDirectory' # Example xNetworking
$Global:DSCResourceName    = 'MSFT_xADDomainDefaultPasswordPolicy' # Example MSFT_xFirewall

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
Write-Host $moduleRoot -ForegroundColor Green;
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit
#endregion


# Begin Testing
try
{

    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $Global:DSCResourceName {

        #region Pester Test Initialization

        $testDomainName = 'contoso.com';
        $testDefaultParams = @{
            DomainName = $testDomainName;
        }
        $testDomainController = 'testserver.contoso.com';
        $testPassword = (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force);
        $testCredential = New-Object System.Management.Automation.PSCredential 'Safemode', $testPassword;

        $fakePasswordPolicy = @{
            ComplexityEnabled = $true;
            LockoutDuration = New-TimeSpan -Minutes 30;
            LockoutObservationWindow = New-TimeSpan -Minutes 30;
            LockoutThreshold = 3;
            MinPasswordAge = New-TimeSpan -Days 1;
            MaxPasswordAge = New-TimeSpan -Days 42;
            MinPasswordLength = 7;
            PasswordHistoryCount = 12;
            ReversibleEncryptionEnabled = $false;
        }

        #endregion

        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {

            Mock -CommandName Assert-Module -ParameterFilter { $ModuleName -eq 'ActiveDirectory' }

            It 'Calls "Assert-Module" to check "ActiveDirectory" module is installed' {
                Mock -CommandName Get-ADDefaultDomainPasswordPolicy { return $fakePasswordPolicy; }

                $result = Get-TargetResource @testDefaultParams;

                Assert-MockCalled -CommandName Assert-Module -ParameterFilter { $ModuleName -eq 'ActiveDirectory' } -Scope It
            }

            It 'Returns "System.Collections.Hashtable" object type' {
                Mock -CommandName Get-ADDefaultDomainPasswordPolicy { return $fakePasswordPolicy; }

                $result = Get-TargetResource @testDefaultParams;

                $result -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Calls "Get-ADDefaultDomainPasswordPolicy" without credentials by default' {
                Mock -CommandName Get-ADDefaultDomainPasswordPolicy -ParameterFilter { $Credential -eq $null } -MockWith { return $fakePasswordPolicy; }

                $result = Get-TargetResource @testDefaultParams;

                Assert-MockCalled -CommandName Get-ADDefaultDomainPasswordPolicy -ParameterFilter { $Credential -eq $null } -Scope It
            }

            It 'Calls "Get-ADDefaultDomainPasswordPolicy" with credentials when specified' {
                Mock -CommandName Get-ADDefaultDomainPasswordPolicy -ParameterFilter { $Credential -eq $testCredential } -MockWith { return $fakePasswordPolicy; }

                $result = Get-TargetResource @testDefaultParams -Credential $testCredential;

                Assert-MockCalled -CommandName Get-ADDefaultDomainPasswordPolicy -ParameterFilter { $Credential -eq $testCredential } -Scope It
            }

            It 'Calls "Get-ADDefaultDomainPasswordPolicy" without server by default' {
                Mock -CommandName Get-ADDefaultDomainPasswordPolicy -ParameterFilter { $Server -eq $null } -MockWith { return $fakePasswordPolicy; }

                $result = Get-TargetResource @testDefaultParams;

                Assert-MockCalled -CommandName Get-ADDefaultDomainPasswordPolicy -ParameterFilter { $Server -eq $null } -Scope It
            }

            It 'Calls "Get-ADDefaultDomainPasswordPolicy" with server when specified' {
                Mock -CommandName Get-ADDefaultDomainPasswordPolicy -ParameterFilter { $Server -eq $testDomainController } -MockWith { return $fakePasswordPolicy; }

                $result = Get-TargetResource @testDefaultParams -DomainController $testDomainController;

                Assert-MockCalled -CommandName Get-ADDefaultDomainPasswordPolicy -ParameterFilter { $Server -eq $testDomainController } -Scope It
            }

        }
        #endregion

        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {

            $testDomainName = 'contoso.com';
            $testDefaultParams = @{
                DomainName = $testDomainName;
            }
            $testDomainController = 'testserver.contoso.com';
            $testPassword = (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force);
            $testCredential = New-Object System.Management.Automation.PSCredential 'Safemode', $testPassword;

            $stubPasswordPolicy = @{
                ComplexityEnabled = $true;
                LockoutDuration = (New-TimeSpan -Minutes 30).TotalMinutes;
                LockoutObservationWindow = (New-TimeSpan -Minutes 30).TotalMinutes;
                LockoutThreshold = 3;
                MinPasswordAge = (New-TimeSpan -Days 1).TotalMinutes;
                MaxPasswordAge = (New-TimeSpan -Days 42).TotalMinutes;
                MinPasswordLength = 7;
                PasswordHistoryCount = 12;
                ReversibleEncryptionEnabled = $true;
            }

            It 'Returns "System.Boolean" object type' {
                Mock -CommandName Get-TargetResource -MockWith { return $stubPasswordPolicy; }

                $result = Test-TargetResource @testDefaultParams;

                $result -is [System.Boolean] | Should Be $true;
            }

            It 'Calls "Get-TargetResource" with "Credential" parameter when specified' {
                Mock -CommandName Get-TargetResource -ParameterFilter { $Credential -eq $testCredential } { return $stubPasswordPolicy; }

                $result = Test-TargetResource @testDefaultParams -Credential $testCredential;

                Assert-MockCalled -CommandName Get-TargetResource -ParameterFilter { $Credential -eq $testCredential } -Scope It
            }

            It 'Calls "Get-TargetResource" with "DomainController" parameter when specified' {
                Mock -CommandName Get-TargetResource -ParameterFilter { $DomainController -eq $testDomainController } { return $stubPasswordPolicy; }

                $result = Test-TargetResource @testDefaultParams -DomainController $testDomainController;

                Assert-MockCalled -CommandName Get-TargetResource -ParameterFilter { $DomainController -eq $testDomainController } -Scope It
            }

            foreach ($propertyName in $stubPasswordPolicy.Keys)
            {
                It "Passes when '$propertyName' parameter matches resource property value" {
                    Mock -CommandName Get-TargetResource -MockWith { return $stubPasswordPolicy; }
                    $propertyDefaultParams = $testDefaultParams.Clone();
                    $propertyDefaultParams[$propertyName] = $stubPasswordPolicy[$propertyName];

                    $result = Test-TargetResource @propertyDefaultParams;

                    $result | Should Be $true;
                }

                It "Fails when '$propertyName' parameter does not match resource property value" {
                    Mock -CommandName Get-TargetResource -MockWith { return $stubPasswordPolicy; }
                    $propertyDefaultParams = $testDefaultParams.Clone();

                    switch ($stubPasswordPolicy[$propertyName].GetType())
                    {
                        'bool' {
                            $propertyDefaultParams[$propertyName] = -not $stubPasswordPolicy[$propertyName];
                        }
                        'string' {
                            $propertyDefaultParams[$propertyName] = 'not{0}' -f $stubPasswordPolicy[$propertyName];
                        }
                        default {
                            $propertyDefaultParams[$propertyName] = $stubPasswordPolicy[$propertyName] + 1;
                        }
                    }

                    $result = Test-TargetResource @propertyDefaultParams;

                    $result | Should Be $false;
                }
            } #end foreach property

        }
        #endregion

        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {

            $testDomainName = 'contoso.com';
            $testDefaultParams = @{
                DomainName = $testDomainName;
            }
            $testDomainController = 'testserver.contoso.com';
            $testPassword = (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force);
            $testCredential = New-Object System.Management.Automation.PSCredential 'Safemode', $testPassword;

            $stubPasswordPolicy = @{
                ComplexityEnabled = $true;
                LockoutDuration = (New-TimeSpan -Minutes 30).TotalMinutes;
                LockoutObservationWindow = (New-TimeSpan -Minutes 30).TotalMinutes;
                LockoutThreshold = 3;
                MinPasswordAge = (New-TimeSpan -Days 1).TotalMinutes;
                MaxPasswordAge = (New-TimeSpan -Days 42).TotalMinutes;
                MinPasswordLength = 7;
                PasswordHistoryCount = 12;
                ReversibleEncryptionEnabled = $true;
            }

            Mock -CommandName Assert-Module -ParameterFilter { $ModuleName -eq 'ActiveDirectory' }

            It 'Calls "Assert-Module" to check "ActiveDirectory" module is installed' {
                Mock -CommandName Set-ADDefaultDomainPasswordPolicy

                $result = Set-TargetResource @testDefaultParams;

                Assert-MockCalled -CommandName Assert-Module -ParameterFilter { $ModuleName -eq 'ActiveDirectory' } -Scope It
            }

            It 'Calls "Set-ADDefaultDomainPasswordPolicy" without "Credential" parameter by default' {
                Mock -CommandName Set-ADDefaultDomainPasswordPolicy -ParameterFilter { $Credential -eq $null }

                $result = Set-TargetResource @testDefaultParams;

                Assert-MockCalled -CommandName Set-ADDefaultDomainPasswordPolicy -ParameterFilter { $Credential -eq $null } -Scope It
            }

            It 'Calls "Set-ADDefaultDomainPasswordPolicy" with "Credential" parameter when specified' {
                Mock -CommandName Set-ADDefaultDomainPasswordPolicy -ParameterFilter { $Credential -eq $testCredential }

                $result = Set-TargetResource @testDefaultParams -Credential $testCredential;

                Assert-MockCalled -CommandName Set-ADDefaultDomainPasswordPolicy -ParameterFilter { $Credential -eq $testCredential } -Scope It
            }

            It 'Calls "Set-ADDefaultDomainPasswordPolicy" without "Server" parameter by default' {
                Mock -CommandName Set-ADDefaultDomainPasswordPolicy -ParameterFilter { $Server -eq $null }

                $result = Set-TargetResource @testDefaultParams;

                Assert-MockCalled -CommandName Set-ADDefaultDomainPasswordPolicy -ParameterFilter { $Server -eq $null } -Scope It
            }

            It 'Calls "Set-ADDefaultDomainPasswordPolicy" with "Server" parameter when specified' {
                Mock -CommandName Set-ADDefaultDomainPasswordPolicy -ParameterFilter { $Server -eq $testDomainController }

                $result = Set-TargetResource @testDefaultParams -DomainController $testDomainController;

                Assert-MockCalled -CommandName Set-ADDefaultDomainPasswordPolicy -ParameterFilter { $Server -eq $testDomainController } -Scope It
            }

            foreach ($propertyName in $stubPasswordPolicy.Keys)
            {
                It "Calls 'Set-ADDefaultDomainPasswordPolicy' with '$propertyName' parameter when specified" {
                    $propertyDefaultParams = $testDefaultParams.Clone();
                    $propertyDefaultParams[$propertyName] = $stubPasswordPolicy[$propertyName];
                    Mock -CommandName Set-ADDefaultDomainPasswordPolicy -ParameterFilter { $PSBoundParameters.ContainsKey($propertyName) }

                    $result = Set-TargetResource @propertyDefaultParams;

                    Assert-MockCalled -CommandName Set-ADDefaultDomainPasswordPolicy -ParameterFilter { $PSBoundParameters.ContainsKey($propertyName) } -Scope It
                }

            } #end foreach property name

        }
        #endregion

    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}

