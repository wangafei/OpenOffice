#**************************************************************
#  
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#  
#    http://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing,
#  software distributed under the License is distributed on an
#  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#  KIND, either express or implied.  See the License for the
#  specific language governing permissions and limitations
#  under the License.
#  
#**************************************************************



package installer::windows::component;

use installer::converter;
use installer::existence;
use installer::exiter;
use installer::files;
use installer::globals;
use installer::windows::idtglobal;
use installer::windows::language;

##############################################################
# Returning a globally unique ID (GUID) for a component
# If the component is new, a unique guid has to be created.
# If the component already exists, the guid has to be 
# taken from a list component <-> guid
# Sample for a guid: {B68FD953-3CEF-4489-8269-8726848056E8}
##############################################################

sub get_component_guid ($)
{	
	my ($componentname) = @_;
	
	# At this time only a template
	my $returnvalue = "\{COMPONENTGUID\}";
	
	# Returning a ComponentID, that is assigned in scp project
	if ( exists($installer::globals::componentid{$componentname}) )
	{
        $installer::logger::Lang->printf("reusing guid %s for component %s\n",
            $installer::globals::componentid{$componentname},
            $componentname);
		$returnvalue = "\{" . $installer::globals::componentid{$componentname} . "\}";
	}
	
	return $returnvalue;	
}

##############################################################
# Returning the directory for a file component.
##############################################################

sub get_file_component_directory ($$$)
{
	my ($componentname, $filesref, $dirref) = @_; 

	my ($component,  $uniquedir);
	my $found = 0;

	foreach my $onefile (@$filesref)
	{
		if ($onefile->{'componentname'} eq $componentname)
		{
            return get_file_component_directory_for_file($onefile, $dirref);
		}
	}
	

    # This component can be ignored, if it exists in a version with
    # extension "_pff" (this was renamed in file::get_sequence_for_file() )
    my $ignore_this_component = 0;
    my $origcomponentname = $componentname;
    my $componentname_pff = $componentname . "_pff";
		
    foreach my $onefile (@$filesref)
    {
        if ($onefile->{'componentname'} eq $componentname_pff)
        {
            return "IGNORE_COMP";
        }	
    }
		
    installer::exiter::exit_program(
        "ERROR: Did not find component \"$origcomponentname\" in file collection",
        "get_file_component_directory");
}




sub get_file_component_directory_for_file ($$)
{
    my ($onefile, $dirref) = @_;

	my $localstyles = $onefile->{'Styles'} // "";
	
	if ( $localstyles =~ /\bFONT\b/ )	# special handling for font files
	{
		return $installer::globals::fontsfolder;
	}
	
	my $destdir = "";
	
	if ( $onefile->{'Dir'} ) { $destdir = $onefile->{'Dir'}; }

	if ( $destdir =~ /\bPREDEFINED_OSSHELLNEWDIR\b/ )	# special handling for shellnew files
	{
		return $installer::globals::templatefolder;
	}

	my $destination = $onefile->{'destination'};
	
	installer::pathanalyzer::get_path_from_fullqualifiedname(\$destination);

	$destination =~ s/\Q$installer::globals::separator\E\s*$//;
	
	# This path has to be defined in the directory collection at "HostName" 

    my $uniquedir = undef;
	if ($destination eq "")		# files in the installation root
	{
		$uniquedir = "INSTALLLOCATION";
	}		
	else
	{
		$found = 0;
	
		foreach my $directory (@$dirref)
		{
			if ($directory->{'HostName'} eq $destination )
			{
				$found = 1;
                $uniquedir = $directory->{'uniquename'};
				last;
			}	
		}

		if ( ! $found)
		{
			installer::exiter::exit_program(
                "ERROR: Did not find destination $destination in directory collection",
                "get_file_component_directory");
		}
	
		
		if ( $uniquedir eq $installer::globals::officeinstalldirectory )
		{
			$uniquedir = "INSTALLLOCATION";		
		}
	}
		
	$onefile->{'uniquedirname'} = $uniquedir;		# saving it in the file collection
	
	return $uniquedir	
}

##############################################################
# Returning the directory for a registry component.
# This cannot be a useful value
##############################################################

sub get_registry_component_directory
{
	my $componentdir = "INSTALLLOCATION";
	
	return $componentdir;
}

##############################################################
# Returning the attributes for a file component.
# Always 8 in this first try?
##############################################################

sub get_file_component_attributes
{
	my ($componentname, $filesref, $allvariables) = @_;
	
	my $attributes;
	
	$attributes = 2;

	# special handling for font files

	my $onefile;
	my $found = 0;

	for ( my $i = 0; $i <= $#{$filesref}; $i++ )
	{
		$onefile = 	${$filesref}[$i];
		my $component = $onefile->{'componentname'};
		
		if ( $component eq $componentname )
		{
			$found = 1;
			last;
		}	
	}

	if (!($found))
	{
		installer::exiter::exit_program("ERROR: Did not find component in file collection", "get_file_component_attributes");
	}

	my $localstyles = "";
	
	if ( $onefile->{'Styles'} ) { $localstyles = $onefile->{'Styles'}; }

	if ( $localstyles =~ /\bFONT\b/ )
	{
		$attributes = 8;	# font files will be deinstalled if the ref count is 0
	}

	if ( $localstyles =~ /\bASSEMBLY\b/ )
	{
		$attributes = 0;	# Assembly files cannot run from source
	}
		
	if ((defined $onefile->{'Dir'} && $onefile->{'Dir'} =~ /\bPREDEFINED_OSSHELLNEWDIR\b/)
        || $onefile->{'needs_user_registry_key'})
	{
		$attributes = 4;	# Files in shellnew dir and in non advertised startmenu entries must have user registry key as KeyPath
	}
	
	# Adding 256, if this is a 64 bit installation set.
	if (( $allvariables->{'64BITPRODUCT'} ) && ( $allvariables->{'64BITPRODUCT'} == 1 )) { $attributes = $attributes + 256; }

	return $attributes	
}

##############################################################
# Returning the attributes for a registry component.
# Always 4, indicating, the keypath is a defined in 
# table registry
##############################################################

sub get_registry_component_attributes
{
	my ($componentname, $allvariables) = @_;

	my $attributes;
	
	$attributes = 4;

	# Adding 256, if this is a 64 bit installation set.
	if (( $allvariables->{'64BITPRODUCT'} ) && ( $allvariables->{'64BITPRODUCT'} == 1 )) { $attributes = $attributes + 256; }
	
	if ( exists($installer::globals::dontdeletecomponents{$componentname}) ) { $attributes = $attributes + 16; } 
	
	return $attributes	
}

##############################################################
# Returning the conditions for a component.
# This is important for language dependent components
# in multilingual installation sets.
##############################################################

sub get_file_component_condition
{
	my ($componentname, $filesref) = @_;
	
	my $condition = "";

	if (exists($installer::globals::componentcondition{$componentname}))
	{
		$condition = $installer::globals::componentcondition{$componentname};
	}

	# there can be also tree conditions for multilayer products
	if (exists($installer::globals::treeconditions{$componentname}))
	{
		if ( $condition eq "" )
		{
			$condition = $installer::globals::treeconditions{$componentname};	
		}
		else
		{
			$condition = "($condition) And ($installer::globals::treeconditions{$componentname})";
		}
	}
	
	return $condition	
}

##############################################################
# Returning the conditions for a registry component.
##############################################################

sub get_component_condition
{
	my ($componentname) = @_;
	
	my $condition;
	
	$condition = "";	# Always ?
	
	if (exists($installer::globals::componentcondition{$componentname}))
	{
		$condition = $installer::globals::componentcondition{$componentname};
	}
	
	return $condition	
}

####################################################################
# Returning the keypath for a component.
# This will be the name of the first file/registry, found in the
# collection $itemsref
# Attention: This has to be the unique (file)name, not the 
# real filename!
####################################################################

sub get_component_keypath ($$)
{
	my ($componentname, $itemsref) = @_;

	my $found = 0;
	my $infoline = "";

	foreach my $oneitem (@$itemsref)
	{
        my $component = $oneitem->{'componentname'};

		if ( ! defined $component)
        {
            installer::scriptitems::print_script_item($oneitem);
            installer::logger::PrintError("item in get_component_keypath has no 'componentname'\n");
            return "";
        }
		if ( $component eq $componentname )
		{
            my $keypath = $oneitem->{'uniquename'};	# "uniquename", not "Name" 
	
            # Special handling for components in
            # PREDEFINED_OSSHELLNEWDIR. These components need as
            # KeyPath a RegistryItem in HKCU
            if ($oneitem->{'userregkeypath'})
            {
                $keypath = $oneitem->{'userregkeypath'};
            }

            # saving it in the file and registry collection
            $oneitem->{'keypath'} = $keypath;
	
            return $keypath
		}

		if ($oneitem->{'componentname'} eq $componentname)
		{
			$found = 1;
			last;
		}
	}

    installer::exiter::exit_program(
        "ERROR: Did not find component in file/registry collection, function get_component_keypath",
        "get_component_keypath");
}

###################################################################
# Creating the file Componen.idt dynamically
# Content: 
# Component ComponentId Directory_ Attributes Condition KeyPath
###################################################################

sub	create_component_table ($$$$$$$)
{
	my ($filesref,
        $registryref,
        $dirref,
        $allfilecomponentsref,
        $allregistrycomponents,
        $basedir,
        $allvariables)
        = @_;

	my @componenttable = ();

	my ($oneline, $infoline);

	installer::windows::idtglobal::write_idt_header(\@componenttable, "component");

	# collect_layer_conditions();


	# File components

	for ( my $i = 0; $i <= $#{$allfilecomponentsref}; $i++ )
	{
		my %onecomponent = ();
		
		$onecomponent{'name'} = ${$allfilecomponentsref}[$i]; 
		$onecomponent{'guid'} = get_component_guid($onecomponent{'name'}); 
		$onecomponent{'directory'} = get_file_component_directory($onecomponent{'name'}, $filesref, $dirref);
		if ( $onecomponent{'directory'} eq "IGNORE_COMP" ) { next; }
		$onecomponent{'attributes'} = get_file_component_attributes($onecomponent{'name'}, $filesref, $allvariables); 
		$onecomponent{'condition'} = get_file_component_condition($onecomponent{'name'}, $filesref); 
		$onecomponent{'keypath'} = get_component_keypath($onecomponent{'name'}, $filesref); 

		$oneline = $onecomponent{'name'} . "\t" . $onecomponent{'guid'} . "\t" . $onecomponent{'directory'} . "\t"  
				. $onecomponent{'attributes'} . "\t" . $onecomponent{'condition'} . "\t" . $onecomponent{'keypath'} . "\n";

		push(@componenttable, $oneline);
	}	

	# Registry components

	for ( my $i = 0; $i <= $#{$allregistrycomponents}; $i++ )
	{
		my %onecomponent = ();
		
		$onecomponent{'name'} = ${$allregistrycomponents}[$i]; 
		$onecomponent{'guid'} = get_component_guid($onecomponent{'name'}); 
		$onecomponent{'directory'} = get_registry_component_directory();
		$onecomponent{'attributes'} = get_registry_component_attributes($onecomponent{'name'}, $allvariables); 
		$onecomponent{'condition'} = get_component_condition($onecomponent{'name'}); 
		$onecomponent{'keypath'} = get_component_keypath($onecomponent{'name'}, $registryref); 

		$oneline = $onecomponent{'name'} . "\t" . $onecomponent{'guid'} . "\t" . $onecomponent{'directory'} . "\t"  
				. $onecomponent{'attributes'} . "\t" . $onecomponent{'condition'} . "\t" . $onecomponent{'keypath'} . "\n";

		push(@componenttable, $oneline);
	}

	# Saving the file

	my $componenttablename = $basedir . $installer::globals::separator . "Componen.idt";
	installer::files::save_file($componenttablename ,\@componenttable);
	$infoline = "Created idt file: $componenttablename\n"; 
	$installer::logger::Lang->print($infoline);
}

####################################################################################
# Returning a component for a scp module gid.
# Pairs are saved in the files collector. 
####################################################################################

sub get_component_name_from_modulegid
{
	my ($modulegid, $filesref) = @_;

	my $componentname = "";
	
	for ( my $i = 0; $i <= $#{$filesref}; $i++ )
	{			
		my $onefile = ${$filesref}[$i];

		if ( $onefile->{'modules'} )
		{
			my $filemodules = $onefile->{'modules'};
			my $filemodulesarrayref = installer::converter::convert_stringlist_into_array_without_newline(\$filemodules, ",");

			if (installer::existence::exists_in_array($modulegid, $filemodulesarrayref))
			{
				$componentname = $onefile->{'componentname'};
				last;
			}
		}
	}
	
	return $componentname;
}

####################################################################################
# Updating the file Environm.idt dynamically
# Content: 
# Environment Name Value Component_
####################################################################################

sub set_component_in_environment_table
{
	my ($basedir, $filesref) = @_;

	my $infoline = "";

	my $environmentfilename = $basedir . $installer::globals::separator . "Environm.idt";
	
	if ( -f $environmentfilename )	# only do something, if file exists
	{
		my $environmentfile = installer::files::read_file($environmentfilename);

		for ( my $i = 3; $i <= $#{$environmentfile}; $i++ )	# starting in line 4 of Environm.idt
		{
			if ( ${$environmentfile}[$i] =~ /^\s*(.*?)\t(.*?)\t(.*?)\t(.*?)\s*$/ )
			{
				my $modulegid = $4; # in Environment table a scp module gid can be used as component replacement

				my $componentname = get_component_name_from_modulegid($modulegid, $filesref);

				if ( $componentname )	# only do something if a component could be found
				{
					$infoline = "Updated Environment table:\n"; 
					$installer::logger::Lang->print($infoline);
					$infoline = "Old line: ${$environmentfile}[$i]\n"; 
					$installer::logger::Lang->print($infoline);

					${$environmentfile}[$i] =~ s/$modulegid/$componentname/;

					$infoline = "New line: ${$environmentfile}[$i]\n"; 
					$installer::logger::Lang->print($infoline);

				}
			}
		}

		# Saving the file
	
		installer::files::save_file($environmentfilename ,$environmentfile);
		$infoline = "Updated idt file: $environmentfilename\n"; 
		$installer::logger::Lang->print($infoline);

	}
}

1;