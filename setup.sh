#!/bin/bash

installDevUtils () {
    printf "\nInstalling Development Utilities...\n"
    cd $2 || return
    if [ -d "$1" ]; then
        printf "\n\nProject $1 already exists...\n"
    else
        if [[ "$1" != "" ]]; then
            gh repo clone "https://github.com/ThisThatApp/$1" "$2/$1" || return
        else
            return
        fi
    fi
}

cloneAndInitEngineering () {
    #$1 = repo name
    #$2 = directory
    [[ "$VIRTUAL_ENV" != "" ]] && deactivate
	cd "$2" || return
    if [ -d "$1" ]; then
        echo "Project $1 already exists..."
		return
	else
		if [[ "$1" != "" ]]; then
            gh repo clone "https://github.com/ThisThatApp/$1" "$2/$1" || return
            cd "$2/$1" || return
            if [[ "$1" != "tt-shared" ]]; then git checkout develop
            fi
            nvm install
             if [[ $1 = "saas-platform" || $1 = "survey-interface" ]]; then 
                # "$(npm install --legacy-peer-deps)"
                echo ""
             else 
                # npm install
                echo ""
            fi
		fi
	fi
}

setupSupportAlgorithms () {
    #$1 = repo name
    #$2 = directory
    brew install python@3.9
    [[ "$VIRTUAL_ENV" != "" ]] && deactivate
    xcode-select --install
    cd "$2" || return
    if [ -d "$1" ]; then
        echo "Project $1 already exists..."
    else
        if [[ "$1" != "" ]]; then
            gh repo clone "https://github.com/ThisThatApp/$1" "$2/$1" || return
        else
            return
        fi
        cd "$2/$1"
        git checkout develop
        python3 -m venv env
        source ./env/bin/activate
        pip3 install --upgrade pip
        pip install -r requirements.txt
    fi
}

dataInstallTTShared () {
    #$1 = repo name
    #$2 = directory
    [[ "$VIRTUAL_ENV" != "" ]] && deactivate
    xcode-select --install
    cd "$2" || return
    if [ -d "$1" ]; then
        printf "\n\nProject $1 already exists..."
    else
        if [[ "$1" != "" ]]; then
            gh repo clone "https://github.com/ThisThatApp/$1" "$2/$1" || return
        else
            return
        fi
        cd "$2/$1"
        npm install
        npm run build
    fi
}

dev_directory="$HOME/Development"

echo "What team have you joined:"
select option in "Engineering" "Data"; do
    case $option in
        Engineering)
            role="engineer"
            break
            ;;
        Data)
            role="data"
            break
            ;;
        *)
            echo "Invalid option. Exiting."
            exit 1
            ;;
    esac
done

command -v brew >/dev/null 2>&1 || {
    printf "\nInstalling Homebrew...\n"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

echo export PATH="/opt/homebrew/bin:$PATH" >> ~/.zshrc

command -v zsh >/dev/null 2>&1 || {
    printf "\nInstalling ZSH...\n"
    brew install zsh
}

if [ ! -f "$HOME/.zshrc" ]; then
    printf "\nInstalling Oh my zsh...\n"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

title="# CUSTOM init script"
dev_utils_init="source ~/Development/development-utilities/src/init.sh"

zshrc_path="$HOME/.zshrc"

if ! grep -q "$title" "$zshrc_path"; then
    printf "\nAdding development utilities to zshrc...\n"
    echo "$title" >> "$zshrc_path"
    echo "$dev_utils_init" >> "$zshrc_path"
fi

engineering_repos=()

three_d="saas-platform"
two_d="creative-effectiveness-platform"
backend="backend"
api="creative-effectiveness-api"
survey_interface="survey-interface"
audience_access="audience-access-app"
db_migrations="database-migrations"
tt_shared="tt-shared"
dev_utils="development-utilities"
support_algorithms="support-algorithms"

engineering_repos+=( "$three_d" "$two_d" "$backend" "$api" "$survey_interface" "$audience_access" "$db_migrations" "$tt_shared")

printf "\n\nSetting up development environment...\n"

if [ -d "$(brew --prefix)/opt/gh" ]; then
    printf "\ngh is already installed\n"
else 
    printf "\nInstalling gh...\n"
    brew install gh

fi

if ! gh auth status >/dev/null 2>&1; then
    printf "\nGithub CLI is not logged in. Please login...\n"
    gh auth login
else
    printf "\nGithub CLI is already logged in.\n"
fi

if [ -d "$dev_directory" ]; then
    printf "\nDevelopment directory already exists.\n"
else
    printf "\nCreating Development directory...\n"
    mkdir "$dev_directory"
fi

command -v node >/dev/null 2>&1 || {
    printf "\nNode is not installed.\nWould you like to install? (Y/n) "
    read -r yn
    case $yn in
        [Yn]* ) brew install node;;
        * ) ;;
    esac
}

if [ -d "$(brew --prefix)/opt/nvm" ]; then
    printf "\nNVM is already installed\n"
else 
    printf "\nInstalling NVM...\n"
    brew install nvm
fi

command -v gcloud >/dev/null 2>&1 || {
    printf "\nInstalling GCP CLI...\n"
    cd "$HOME"
    if [ -d "$HOME/google-cloud-sdk" ]; then
        cd google-cloud-sdk
        ./install.sh
        ./bin/gcloud init
    else
        curl -o gcp_download.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-471.0.0-darwin-x86_64.tar.gz
        tar -xzvf gcp_download.tar.gz
        rm gcp_download.tar.gz
    fi
    cd "$HOME"
}

if [ -f "$HOME/cloud-sql-proxy" ]; then
    printf "\nCloud SQL Proxy is already installed\n"
else 
    printf "\nInstalling Cloud SQL Proxy...\n"
    cd "$HOME"
    curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.10.1/cloud-sql-proxy.darwin.arm64
    chmod +x cloud_sql_proxy
fi

[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && \. "$(brew --prefix)/opt/nvm/nvm.sh"
installDevUtils "$dev_utils" "$dev_directory"
if [ $role == "engineer" ]; then
    for item in "${engineering_repos[@]}"; do
        cloneAndInitEngineering "$item" "$dev_directory"
    done
elif [ $role == "data" ]; then
    setupSupportAlgorithms "$support_algorithms" "$dev_directory"
    dataInstallTTShared "$tt_shared" "$dev_directory"
else
    printf "developer not defined"
fi

if [ -d "/Applications/DBeaver.app" ]; then
    printf "\nBeavs is already installed\n"
else 
    printf "\nBeavs Inbound...\n"
    brew install --cask dbeaver-community
fi

vs_code="Visual Studio Code"

if [ -d "/Applications/$vs_code.app" ]; then
    printf "\nVS Code is already installed\n"
else 
    printf "\nVS Code Inbound...\n"
    brew install --cask visual-studio-code
fi

printf "\n\n\n\n\n\nDevelopment environment setup complete.\n\nPlease restart your terminal.\n\n"

open https://analytics.thisthatapp.com/panel/teams