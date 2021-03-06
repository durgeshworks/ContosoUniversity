$assembly = [System.Reflection.Assembly]::LoadFrom("C:\windows\system32\inetsrv\Microsoft.Web.Administration.dll")
#$assembly = =[System.Reflection.Assembly]::LoadWithPartialName(“Microsoft.Web.Administration”)
# helper function to unlock sectiongroups
function unlockSectionGroup($group)
{
    foreach ($subGroup in $group.SectionGroups)
    {
        unlockSectionGroup($subGroup)
    }
    foreach ($section in $group.Sections)
    {
        $section.OverrideModeDefault = "Allow"
    }
}

# initial work
# load ServerManager
$mgr = new-object Microsoft.Web.Administration.ServerManager
# load appHost config
$conf = $mgr.GetApplicationHostConfiguration()

# unlock all sections in system.webServer
unlockSectionGroup(
     $conf.RootSectionGroup.SectionGroups["system.webServer"])
     