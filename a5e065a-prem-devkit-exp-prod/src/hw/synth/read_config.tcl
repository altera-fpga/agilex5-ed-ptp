# ######################################################################## 
# Copyright (C) 2025 Altera Corporation.
# SPDX-License-Identifier: MIT
# ######################################################################## 

# reading configuration from file

# Function to read a parameter from a file
proc read_parameter {filename param_name {valid_values {}}} {
    # Check if file exists
    if {![file exists $filename]} {
        puts "Error: File '$filename' does not exist. Please provide a file named config.txt located in the synth dir which specifies the required configuration to build.The supported configurations are 10G_NON_ANLT, 25G_NON_ANLT"
        qexit -error
        return ""
    }
    
    # Open file for reading
    set fp [open $filename r]
    
    # Read file line by line
    while {[gets $fp line] >= 0} {
        # Skip empty lines and comments (lines starting with #)
        if {[string trim $line] eq "" || [string index [string trim $line] 0] eq "#"} {
            continue
        }
        
        # Look for parameter in format: param_name = value or param_name=value
        if {[regexp "^\\s*${param_name}\\s*=\\s*(.*)$" $line match value]} {
            close $fp
            set trimmed_value [string trim $value]
            
            # If valid values list is provided, check if value is valid
            if {[llength $valid_values] > 0} {
                if {$trimmed_value in $valid_values} {
                    return $trimmed_value
                } else {
                    puts "Error: Invalid value '$trimmed_value' for parameter '$param_name'"
                    puts "Valid values are: [join $valid_values {, }]"
                    qexit -error
                    return ""
                }
            }
            
            return $trimmed_value
        }
    }
    
    close $fp
    puts "Warning: Parameter '$param_name' not found in file '$filename'"
    return ""
}

set valid_configs {10G_NON_ANLT 25G_NON_ANLT}
set code [catch {
    set config_file "config.txt"
    set param_value [read_parameter $config_file "Configuration" $valid_configs] 
} result]

if {$code == 1} {
    qexit -error
}
