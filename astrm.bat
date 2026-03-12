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

if "%1" == "pack" (
    if "%2" == "windows" (
        echo Building windows setup executable.
        echo Running command: dart run inno_bundle:build --release --build-args="--dart-define-from-file=.env"
        dart run inno_bundle:build --release --build-args="--dart-define-from-file=.env"
    ) else (
        echo "Only windows packaging is supported at the moment. Please specify 'windows' as the second argument."
        exit /b 1
    )
)

echo Running command: flutter %* --dart-define-from-file=.env

flutter %* --dart-define-from-file=.env