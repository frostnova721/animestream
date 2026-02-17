@echo off
setlocal

if not exist ".env" (
    echo .env file not found in the directory. Creating a default .env file...
    echo Please update the .env file with your actual API URL and Simkl credentials for the application to work properly.
    (
        echo COMMENTUM_API_URL=your_api_url
        echo SIMKL_CLIENT_ID=your_simkl_client_id
        echo SIMKL_CLIENT_SECRET=your_simkl_client_secret
    ) > .env
)

echo Running command: flutter %* --dart-define-from-file=.env

flutter %* --dart-define-from-file=.env