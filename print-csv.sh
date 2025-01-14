#!/bin/bash
# This function requires perl package need to be installed before use
function print_csv() {
    perl -we '
      sub max( @ ) {
        my $max = shift;
        map { $max = $_ if $_ > $max } @_;
        return $max;
      }

      sub transpose( @ ) {
        my @matrix = @_;
        my $width  = scalar @{ $matrix[ 0 ] };
        my $height = scalar @matrix;

        return map { my $x = $_; [ map { $matrix[ $_ ][ $x ] } 0 .. $height - 1 ] } 0 .. $width - 1;
      }

      # Read all lines, as arrays of fields
      my @lines = map { s/\r?\n$//; [ split /,/ ] } <>;
    
      # Calculate maximum column widths
      my $widths =
        join "",

        # For each column, get the longest length plus 2 for padding
        map { 'A' . ( 2 + max map { length } @$_ ) }

        # Get arrays of columns
        transpose(@lines);

      # Print top border without line numbers and with proper spacing
      print "+" . join("+", map { "-" x (2 + max(map { length } @$_)) } transpose(@lines)) . "+\n";

      # Format all lines with pack and print row with borders
      foreach my $line (@lines) {
        print "|" . pack($widths, @$line) . "|\n";
      }

      # Print bottom border without line numbers
      print "+" . join("+", map { "-" x (2 + max(map { length } @$_)) } transpose(@lines)) . "+\n";
    ' $1 | less -NS
}

