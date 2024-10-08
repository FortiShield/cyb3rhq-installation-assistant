#!/bin/bash

# Cyb3rhq installer: offline download
# Copyright (C) 2023, Cyb3rhq Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

# Checks the necessary dependencies for the installation
function offline_checkDependencies() {

    dependencies=( curl tar gnupg openssl lsof )

    common_logger "Checking installed dependencies for Offline installation."
    for dep in "${dependencies[@]}"; do
        if [ "${sys_type}" == "yum" ]; then
            eval "yum list installed 2>/dev/null | grep -q -E ^"${dep}"\\."
        elif [ "${sys_type}" == "apt-get" ]; then
            eval "apt list --installed 2>/dev/null | grep -q -E ^"${dep}"\/"
        fi
        
        if [ "${PIPESTATUS[0]}" != 0 ]; then
            common_logger -e "${dep} is necessary for the offline installation."
            exit 1
        fi
    done
    common_logger -d "Offline dependencies are installed."

}

# Checks the necessary packages needed for a Cyb3rhq component
function offline_checkPrerequisites(){

    dependencies=("$@")
    common_logger "Checking prerequisites for Offline installation."
    for dep in "${dependencies[@]}"; do
        if [ "${sys_type}" == "yum" ]; then
            eval "yum list installed 2>/dev/null | grep -q -E ^"${dep}"\\."
        elif [ "${sys_type}" == "apt-get" ]; then
            eval "apt list --installed 2>/dev/null | grep -q -E ^"${dep}"\/"
        fi
        
        if [ "${PIPESTATUS[0]}" != 0 ]; then
            common_logger -e "${dep} is necessary for the offline installation."
            exit 1
        fi
    done
    common_logger -d "Offline prerequisites are installed."
}

# Checks the necessary files for the installation
function offline_checkPreinstallation() {

    offline_tarfile="${base_dest_folder}.tar.gz"
    common_logger "Checking ${offline_tarfile} file."
    if [ ! -f "${base_path}/${offline_tarfile}" ]; then
        common_logger -e "The ${offline_tarfile} file was not found in ${base_path}."
        exit 1
    fi
    common_logger -d "${offline_tarfile} was found correctly."

}

# Extracts the files for the offline installation and check its content
function offline_extractFiles() {

    common_logger -d "Extracting files from ${offline_tarfile}"
    if [ ! -d "${base_path}/cyb3rhq-offline/" ]; then
        eval "tar -xzf ${offline_tarfile} ${debug}"

        if [ ! -d "${base_path}/cyb3rhq-offline/" ]; then
            common_logger -e "The ${offline_tarfile} file could not be decompressed."
            exit 1
        fi
    fi

    offline_files_path="${base_path}/cyb3rhq-offline/cyb3rhq-files"
    offline_packages_path="${base_path}/cyb3rhq-offline/cyb3rhq-packages"

    required_files=(
        "${offline_files_path}/filebeat.yml"
        "${offline_files_path}/GPG-KEY-CYB3RHQ"
        "${offline_files_path}/cyb3rhq-filebeat-*.tar.gz"
        "${offline_files_path}/cyb3rhq-template.json"
    )
    
    if [ "${sys_type}" == "apt-get" ]; then
        required_files+=("${offline_packages_path}/filebeat-oss-*.deb" "${offline_packages_path}/cyb3rhq-dashboard_*.deb" "${offline_packages_path}/cyb3rhq-indexer_*.deb" "${offline_packages_path}/cyb3rhq-manager_*.deb")
    elif [ "${sys_type}" == "rpm" ]; then
        required_files+=("${offline_packages_path}/filebeat-oss-*.rpm" "${offline_packages_path}/cyb3rhq-dashboard_*.rpm" "${offline_packages_path}/cyb3rhq-indexer_*.rpm" "${offline_packages_path}/cyb3rhq-manager_*.rpm")
    fi

    for file in "${required_files[@]}"; do
        if ! compgen -G "${file}" > /dev/null; then
            common_logger -e "Missing necessary offline file: ${file}"
            exit 1
        fi
    done

    common_logger -d "Offline files extracted successfully."
}
