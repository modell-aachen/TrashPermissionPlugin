package Foswiki::Plugins::TrashPermissionPlugin;

use strict;
use warnings;

use Foswiki::Func ();
use Foswiki::Plugins ();

use version;
our $VERSION = version->declare( '1.0.0' );
our $RELEASE = "1.0.0";
our $NO_PREFS_IN_TOPIC = 1;
our $SHORTDESCRIPTION = 'Ensures correct topic permission after topic deletion.';

sub initPlugin {
  my ( $topic, $web, $user, $installWeb ) = @_;

  if ( $Foswiki::Plugins::VERSION < 2.0 ) {
      Foswiki::Func::writeWarning( 'Version mismatch between ',
          __PACKAGE__, ' and Plugins.pm' );
      return 0;
  }

  return 1;
}

sub afterRenameHandler {
  my ( $oldWeb, $oldTopic, $oldAttachment, $newWeb, $newTopic, $newAttachment ) = @_;

  my $trashWeb = $Foswiki::cfg{TrashWebName} || 'Trash';
  my $isRestore = ($oldWeb eq $trashWeb && $newWeb ne $trashWeb) || 0;
  my $isDelete = ($oldWeb ne $trashWeb && $newWeb eq $trashWeb) || 0;
  return unless ($isDelete || $isRestore);

  my $meta = Foswiki::Meta->load( $Foswiki::Plugins::SESSION, $newWeb, $newTopic );
  my $text = $meta->getEmbeddedStoreForm();
  my @lines = split( "\n", $text );
  my @newLines = ();

  if ( $isDelete ) {
    foreach my $line (@lines) {
      $line =~ s/^\s{3}\*\sSet\s((ALLOW|DENY).+)/%STORED_PERMISSION{$1}%/;
      $line =~ s/%META:PREFERENCE{(.+)}%/%META:STOREDPREFERENCE{$1}%/g;
      push ( @newLines, $line );
    }
  }

  if ( $isRestore ) {
    foreach my $line (@lines) {
      $line =~ s/^%STORED_PERMISSION{(.+)}%/   * Set $1/;
      $line =~ s/%META:STOREDPREFERENCE{(.+)}%/%META:PREFERENCE{$1}%/g;
      push ( @newLines, $line );
    }
  }

  $text = join( "\n", @newLines );
  my $prefix = $isDelete ? '' : 'STORED';
  $meta->remove( $prefix . 'PREFERENCE' );
  $meta->setEmbeddedStoreForm( $text );
  $meta->save( { dontlog => 1, minor => 1} );
}

1;

__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Author: Sven Meyer <meyer@modell-aachen.de>

Copyright (C) 2008-2013 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.