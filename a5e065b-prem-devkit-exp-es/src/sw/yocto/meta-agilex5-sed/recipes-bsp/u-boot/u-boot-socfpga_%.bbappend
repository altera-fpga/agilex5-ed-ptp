python() {
    # Retrieve the SRC_URI list and split it into individual items
    src_uri_list = (d.getVar('SRC_URI') or "").split()

    # Define a list of files that you want to remove from SRC_URI
    files_to_remove = ['file://0001-arm-Add-dwarf-4-to-compilation-flag.patch' ,
                       'file://0001-arm-agilex-add-board-configuration.patch' ,
                       'file://0001-arm-stratix10-add-board-configuration.patch']

    # Filter out the files to remove
    filtered_src_uri_list = [item for item in src_uri_list if not any(file_to_remove in item for file_to_remove in files_to_remove)]

    # Join the filtered list back into a string and set it as the new SRC_URI
    d.setVar('SRC_URI', " ".join(filtered_src_uri_list))
}

