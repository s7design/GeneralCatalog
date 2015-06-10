# --
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get selenium object
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        # get helper object
        $Kernel::OM->ObjectParamAdd(
            'Kernel::System::UnitTest::Helper' => {
                RestoreSystemConfiguration => 1,
            },
        );
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # get sysconfig object
        my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

        # reset sysconfig used in tests
        my @ConfigList = (qw(Comment2 Permissions));
        for my $ConfigItem (@ConfigList) {
            $SysConfigObject->ConfigItemReset(
                Name => 'GeneralCatalogPreferences###' . $ConfigItem,
            );
        }

        # create and log in test user
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        # ---------------------------------------------------- #
        # Test case: Comment2                                  #
        # ---------------------------------------------------- #

        # navigate to AdminGeneralCatalog screen
        $Selenium->get("${ScriptAlias}index.pl?Action=AdminGeneralCatalog");

        # click "Add Catalog Class"
        $Selenium->find_element("//button[\@value='Add'][\@type='submit']")->click();

        # verify that general catalog preference Comment2 is not present while invalid
        my $Success;
        eval {
            $Success = $Selenium->find_element( "#Comment2", 'css' )->is_enabled();
        };
        $Self->False(
            $Success,
            "#Comment2 in not enabled!",
        );

        # get general catalog preference Comment2 default sysconfig
        my %PreferenceComment2Config = $SysConfigObject->ConfigItemGet(
            Name    => 'GeneralCatalogPreferences###Comment2',
            Default => 1,
        );

        # set general catalog preference Comment2 to valid
        my %PreferenceComment2ConfigUpdate = map { $_->{Key} => $_->{Content} }
            grep { defined $_->{Key} } @{ $PreferenceComment2Config{Setting}->[1]->{Hash}->[1]->{Item} };

        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'GeneralCatalogPreferences###Comment2',
            Value => \%PreferenceComment2ConfigUpdate,
        );

        # refresh screen for sysconfig update to take effect
        $Selenium->refresh();

        # verify that general catalog preference Comment2 is present while valid
        $Success = $Selenium->find_element( "#Comment2", 'css' )->is_enabled();
        $Self->True(
            $Success,
            "#Comment2 in enabled!",
        );

        # create real test catalog class
        my $CatalogClassDsc  = "CatalogClassDsc" . $Helper->GetRandomID();
        my $CatalogClassName = "CatalogClassName" . $Helper->GetRandomID();
        $Selenium->find_element( "#ClassDsc",                  'css' )->send_keys($CatalogClassDsc);
        $Selenium->find_element( "#Name",                      'css' )->send_keys($CatalogClassName);
        $Selenium->find_element( "#Comment",                   'css' )->send_keys("Selenium catalog class");
        $Selenium->find_element( "#ValidID option[value='1']", 'css' )->click();
        $Selenium->find_element("//button[\@value='Submit'][\@type='submit']")->click();

        # click "Add Catalog Item"
        $Selenium->find_element("//button[\@value='Add'][\@type='submit']")->click();

        # create real test catalog item
        my $CatalogClassItem = "CatalogClassItem" . $Helper->GetRandomID();
        $Selenium->find_element( "#Name",                      'css' )->send_keys($CatalogClassItem);
        $Selenium->find_element( "#Comment",                   'css' )->send_keys("Selenium catalog item");
        $Selenium->find_element( "#ValidID option[value='1']", 'css' )->click();

        # set included queue attribute Comment2
        $Selenium->find_element( "#Comment2", 'css' )->send_keys('GeneralCatalogPreferencesGeneric Comment2');
        $Selenium->find_element("//button[\@value='Submit'][\@type='submit']")->click();

        # get test catalog items IDs
        my @CatalogItemIDs;
        for my $CatalogItems ( $CatalogClassName, $CatalogClassItem ) {
            my $CatalogClassItemData = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
                Class => $CatalogClassDsc,
                Name  => $CatalogItems,
            );
            my $CatalogItemID = $CatalogClassItemData->{ItemID};
            push @CatalogItemIDs, $CatalogItemID;
        }

        # check new test catalog item Comment2 value
        $Selenium->find_element(
            "//a[contains(\@href, \'Action=AdminGeneralCatalog;Subaction=ItemEdit;ItemID=$CatalogItemIDs[1]' )]"
        )->click();

        $Self->Is(
            $Selenium->find_element( '#Comment2', 'css' )->get_value(),
            'GeneralCatalogPreferencesGeneric Comment2',
            "#Comment2 stored value",
        );

        # update Comment2
        my $UpdateComment2 = "Updated comment for GeneralCatalogPreferencesGeneric Comment2";
        $Selenium->find_element( "#Comment2", 'css' )->clear();
        $Selenium->find_element( "#Comment2", 'css' )->send_keys($UpdateComment2);
        $Selenium->find_element("//button[\@value='Submit'][\@type='submit']")->click();

        # check updated Comment2 value
        $Selenium->find_element( $CatalogClassItem, 'link_text' )->click();
        $Self->Is(
            $Selenium->find_element( '#Comment2', 'css' )->get_value(),
            $UpdateComment2,
            "#Comment2 updated value",
        );

        # ---------------------------------------------------- #
        # Test case: Permissions                               #
        # ---------------------------------------------------- #

        # navigate to AdminGeneralCatalog screen
        $Selenium->get("${ScriptAlias}index.pl?Action=AdminGeneralCatalog");

        # click on "ITSM::ConfigItem::Class"
        $Selenium->find_element( "ITSM::ConfigItem::Class", 'link_text' )->click();

        # click "Add Catalog Item"
        $Selenium->find_element("//button[\@value='Add'][\@type='submit']")->click();

        # verify that general catalog preference Permissions is not present while invalid
        undef $Success;
        eval {
            $Success = $Selenium->find_element( "#Permissions", 'css' )->is_enabled();
        };
        $Self->False(
            $Success,
            "#Permissions in not enabled!",
        );

        # get general catalog preference Comment2 default sysconfig
        my %PreferencePermissionsConfig = $SysConfigObject->ConfigItemGet(
            Name    => 'GeneralCatalogPreferences###Permissions',
            Default => 1,
        );

        # set general catalog preference Comment2 to valid
        my %PreferencePermissionsConfigUpdate = map { $_->{Key} => $_->{Content} }
            grep { defined $_->{Key} } @{ $PreferencePermissionsConfig{Setting}->[1]->{Hash}->[1]->{Item} };

        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'GeneralCatalogPreferences###Permissions',
            Value => \%PreferencePermissionsConfigUpdate,
        );

        # refresh screen for sysconfig update to take effect
        $Selenium->refresh();

        # verify that general catalog preference Permissions is present while valid
        $Success = $Selenium->find_element( "#Permissions", 'css' )->is_enabled();
        $Self->True(
            $Success,
            "#Permissions in enabled!",
        );

        # delete created test catalog class
        for my $CatalogItem (@CatalogItemIDs) {

            # get DB object
            my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

            $Success = $DBObject->Do(
                SQL => "DELETE FROM general_catalog_preferences WHERE general_catalog_id = $CatalogItem",
            );
            $Self->True(
                $Success,
                "CatalogItemID $CatalogItem preference - deleted",
            );
            $Success = $DBObject->Do(
                SQL => "DELETE FROM general_catalog WHERE id = $CatalogItem",
            );
            $Self->True(
                $Success,
                "CatalogItemID $CatalogItem - deleted",
            );
        }

        # clean up cache
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp( Type => 'GeneralCatalog' );

        }
);

1;