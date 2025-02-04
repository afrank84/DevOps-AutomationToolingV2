#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use JSON;
use File::Slurp;
use PDF::API2;   # for PDF export

# File to store habit data
my $data_file = "habits.json";

# Global hash: keys are habit names, values are arrayrefs of 31 booleans (0 or 1)
my %habits;
# A helper hash to store checkbutton variable references per habit
my %check_vars;

# Set a default font for the application
my $default_font = "Arial 14";
my $mw = MainWindow->new;
$mw->optionAdd("*Font", $default_font);
$mw->title("Habit Tracker");

# Frame for the table
my $tableFrame = $mw->Frame()->pack(-fill => 'both', -expand => 1);

# Bottom frame for adding habits, clearing, and exporting
my $bottomFrame = $mw->Frame()->pack(-side => 'bottom', -fill => 'x', -padx => 10, -pady => 10);
my $habitEntry = $bottomFrame->Entry(-width => 30);
$habitEntry->pack(-side => 'left', -padx => 5);
my $addBtn = $bottomFrame->Button(
    -text    => "Add Habit",
    -command => \&addHabit
);
$addBtn->pack(-side => 'left', -padx => 5);
my $clearBtn = $bottomFrame->Button(
    -text    => "Clear",
    -command => \&clearAll
);
$clearBtn->pack(-side => 'left', -padx => 5);
my $exportBtn = $bottomFrame->Button(
    -text    => "Export",
    -command => \&exportDialog
);
$exportBtn->pack(-side => 'left', -padx => 5);

##############################
# Persistence subroutines

sub load_habits {
    if (-e $data_file) {
        my $json_text = do { local $/; open my $fh, '<', $data_file or return; <$fh> };
        %habits = %{ decode_json($json_text) };
    }
}

sub save_habits {
    open my $fh, '>', $data_file or die "Cannot open $data_file: $!";
    print $fh encode_json(\%habits);
    close $fh;
}

##############################
# Function to (re)build the table

sub refresh_table {
    # Clear existing table frame
    $tableFrame->destroy;
    $tableFrame = $mw->Frame()->pack(-fill => 'both', -expand => 1);

    # Configure grid weights for columns 0 to 32 so they expand
    for my $col (0 .. 32) {
        $tableFrame->gridColumnconfigure($col, -weight => 1);
    }

    # Header row
    $tableFrame->Label(
        -text       => "Habit",
        -borderwidth=> 1,
        -relief     => 'solid',
        -padx       => 10  # extra left/right padding for header as well
    )->grid(-row => 0, -column => 0, -sticky => 'nsew');
    for my $day (1 .. 31) {
        $tableFrame->Label(
            -text       => $day,
            -borderwidth=> 1,
            -relief     => 'solid'
        )->grid(-row => 0, -column => $day, -sticky => 'nsew');
    }
    $tableFrame->Label(
        -text       => "Action",
        -borderwidth=> 1,
        -relief     => 'solid'
    )->grid(-row => 0, -column => 32, -sticky => 'nsew');

    # Ensure header row has a minimum height
    $tableFrame->gridRowconfigure(0, -minsize => 40);

    # Data rows
    my $row = 1;
    foreach my $habit ( sort keys %habits ) {
        # Habit name label with extra left/right padding
        $tableFrame->Label(
            -text       => $habit,
            -borderwidth=> 1,
            -relief     => 'solid',
            -padx       => 10
        )->grid(-row => $row, -column => 0, -sticky => 'nsew');

        # Prepare checkbutton variables for this habit
        $check_vars{$habit} = [] unless exists $check_vars{$habit};
        for my $day (1 .. 31) {
            my $index = $day - 1;
            my $state = defined $habits{$habit}->[$index] ? $habits{$habit}->[$index] : 0;
            my $var;
            if ( defined $check_vars{$habit}->[$index] ) {
                $var = $check_vars{$habit}->[$index];
            } else {
                $var = \$habits{$habit}->[$index];
                $check_vars{$habit}->[$index] = $var;
            }
            $$var = $state;
            $tableFrame->Checkbutton(
                -variable => $var,
                -command  => sub {
                    $habits{$habit}->[$index] = $$var ? 1 : 0;
                    save_habits();
                },
            )->grid(-row => $row, -column => $day, -sticky => 'nsew');
        }
        # Remove button for habit: shows "X" with red background
        $tableFrame->Button(
            -text              => "X",
            -bg                => "red",
            -fg                => "white",
            -activebackground  => "darkred",
            -command           => sub {
                my $response = $mw->Dialog(
                    -text    => "Remove habit '$habit'?",
                    -title   => "Confirm Remove",
                    -bitmap  => 'question',
                    -buttons => [ "Yes", "No" ]
                )->Show;
                if ( $response eq "Yes" ) {
                    delete $habits{$habit};
                    delete $check_vars{$habit};
                    save_habits();
                    refresh_table();
                }
            }
        )->grid(-row => $row, -column => 32, -sticky => 'nsew');

        # Ensure each row has a minimum height
        $tableFrame->gridRowconfigure($row, -minsize => 40, -weight => 1);
        $row++;
    }
}

##############################
# Add habit function (uses the entry in the main window)

sub addHabit {
    my $name = $habitEntry->get;
    if ($name eq "") {
        $mw->messageBox(-message => "Please enter a habit name.", -type => "OK", -icon => "info");
        return;
    }
    if (exists $habits{$name}) {
        $mw->messageBox(-message => "Habit already exists!", -type => "OK", -icon => "error");
        return;
    }
    # Initialize 31 days to unchecked
    $habits{$name} = [ (0) x 31 ];
    save_habits();
    $habitEntry->delete(0, 'end');
    refresh_table();
}

##############################
# Clear function: only uncheck all checkboxes without deleting any habit

sub clearAll {
    foreach my $habit ( keys %habits ) {
        for my $i (0 .. 30) {
            $habits{$habit}->[$i] = 0;
            if ( exists $check_vars{$habit} and defined $check_vars{$habit}->[$i] ) {
                ${ $check_vars{$habit}->[$i] } = 0;
            }
        }
    }
    save_habits();
    refresh_table();
}

##############################
# Export dialog and export functions

sub exportDialog {
    my $top = $mw->Toplevel;
    $top->title("Export Progress");
    $top->Label(-text => "Select Export Format:")->pack(-padx => 10, -pady => 10);
    my $btnFrame = $top->Frame()->pack(-padx => 10, -pady => 10);
    $btnFrame->Button(-text => "JSON", -command => sub { exportJSON(); $top->destroy })->pack(-side => 'left', -padx => 5);
    $btnFrame->Button(-text => "CSV",  -command => sub { exportCSV();  $top->destroy })->pack(-side => 'left', -padx => 5);
    $btnFrame->Button(-text => "PDF",  -command => sub { exportPDF();  $top->destroy })->pack(-side => 'left', -padx => 5);
}

sub exportJSON {
    my $file = $mw->getSaveFile(
        -defaultextension => '.json',
        -filetypes => [['JSON Files', '*.json'], ['All Files', '*']]
    );
    return unless $file;
    open my $fh, '>', $file or do {
        $mw->messageBox(-message => "Cannot open file: $file", -type => "OK", -icon => "error");
        return;
    };
    print $fh encode_json(\%habits);
    close $fh;
    $mw->messageBox(-message => "Exported to $file", -type => "OK");
}

sub exportCSV {
    my $file = $mw->getSaveFile(
        -defaultextension => '.csv',
        -filetypes => [['CSV Files', '*.csv'], ['All Files', '*']]
    );
    return unless $file;
    open my $fh, '>', $file or do {
        $mw->messageBox(-message => "Cannot open file: $file", -type => "OK", -icon => "error");
        return;
    };
    # Write CSV header
    print $fh "Habit," . join(",", (1..31)) . "\n";
    foreach my $habit ( sort keys %habits ) {
        my @row = ($habit, map { $habits{$habit}->[$_ - 1] // 0 } (1..31));
        print $fh join(",", @row) . "\n";
    }
    close $fh;
    $mw->messageBox(-message => "Exported to $file", -type => "OK");
}

sub exportPDF {
    my $file = $mw->getSaveFile(
        -defaultextension => '.pdf',
        -filetypes => [['PDF Files', '*.pdf'], ['All Files', '*']]
    );
    return unless $file;
    my $pdf = PDF::API2->new();
    my $page = $pdf->page();
    $page->mediabox('A4');
    my $font = $pdf->corefont('Helvetica', -encoding => 'latin1');
    my $text = $page->text();
    $text->font($font, 10);

    # Starting coordinates
    my $x = 50;
    my $y = 800;
    # Print header line
    $text->translate($x, $y);
    my $header = "Habit, " . join(", ", (1..31));
    $text->text($header);
    $y -= 20;

    foreach my $habit (sort keys %habits) {
        $text->translate($x, $y);
        # Represent checked days with a tick (✓) and unchecked as empty
        my @vals = map { $_ ? "✓" : "" } @{$habits{$habit}};
        my $line = $habit . ", " . join(", ", @vals);
        $text->text($line);
        $y -= 15;
        # Start a new page if we run out of space
        if ($y < 50) {
            $page = $pdf->page();
            $page->mediabox('A4');
            $text = $page->text();
            $text->font($font, 10);
            $y = 800;
        }
    }
    $pdf->saveas($file);
    $mw->messageBox(-message => "Exported to $file", -type => "OK");
}

##############################
# Start up: load habits and build table

load_habits();
refresh_table();

MainLoop;
