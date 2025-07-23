@echo off
setlocal EnableDelayedExpansion
title Sploder Timecapsule
cd assets

:: Server configuration
set "API_SERVER=https://sploder.us.to/timecapsule/api.php"

:: Initialize the current page and games per page
set /a games_per_page=15


:searchtypeselect
cls
echo Available search types:
echo ------------------------------------------------------------------------------------------------------------------
echo 1 - Username
echo 2 - Game Name
echo ------------------------------------------------------------------------------------------------------------------
set /p "searchtype=Enter Search Type: "

:: Validate the user input
if "%searchtype%"=="1" goto usernameselect
if "%searchtype%"=="2" goto gamenameselect
echo Invalid choice! Press any key to try again...
pause >nul
goto searchtypeselect

:gamenameselect
cls
echo 0 - Back
echo ------------------------------------------------------------------------------------------------------------------
set /p "gamename=Enter Game Name: "

if "%gamename%"=="0" goto searchtypeselect

:: Use a temporary variable with delayed expansion
set "rawname=%gamename%"

:: PowerShell to URL-encode, with correct quoting
for /f "delims=" %%A in ('powershell -NoProfile -Command "[uri]::EscapeDataString(\"!rawname!\")"') do (
    set "encoded_name=%%A"
)

:: Use the encoded name in the URL
set "url=%API_SERVER%?type=check_gamename_exists&gamename=%encoded_name%"

:: Curl request
for /f "delims=" %%G in ('curl -s "%url%"') do set "game_count=%%G"

if "%game_count%"=="0" (
    goto nogamesgamename
)

:gametypegamename
cls
echo Loading... This will take a while.
echo Too slow? Enter a longer name to narrow down the search.
:: Initialize variables
set "found_game_types=0"
set "counter=0"

for /f "delims=" %%T in ('curl -s "%API_SERVER%?type=get_gametypes_by_gamename&gamename=%encoded_name%"') do (
    set /a counter+=1
    if "!counter!"=="1" (
        cls
    )
    set "type_option!counter!=%%T"

    if "%%T"=="2" (
        echo !counter! - Platformer
        set /a current_page=1
    ) else if "%%T"=="1" (
        echo !counter! - Shooter
        set /a current_page=1
    ) else if "%%T"=="5" (
        echo !counter! - Physics
        set /a current_page=1
    ) else if "%%T"=="3" (
        echo !counter! - Algorithm Crew
        set /a current_page=1
    ) else if "%%T"=="7" (
        echo !counter! - Arcade
        set /a current_page=1
    ) else (
        set /a counter-=1
    )
)

if %counter%==0 (
    goto nogamesgamename
)

echo 0 - Back
echo ------------------------------------------------------------------------------------------------------------------
set /p "choice=Enter Game Type: "

if "%choice%"=="0" goto gamenameselect

set "valid_choice=0"
for /l %%N in (1,1,%counter%) do (
    if "%choice%"=="%%N" (
        set "type=!type_option%%N!"
        set "valid_choice=1"
    )
)

:printtablegamename
cls
set /a offset=(%current_page%-1)*%games_per_page

:: Get total number of games to calculate total pages
for /f "tokens=1" %%G in ('curl -s "%API_SERVER%?type=count_games_by_gamename_type&gamename=%encoded_name%&game_type=%type%"') do (
    set /a total_games=%%G
)

:: Calculate total pages
set /a total_pages=(%total_games% + %games_per_page% - 1) / %games_per_page%
if %total_games% lss %games_per_page% set /a total_pages=1
if %total_games% gtr 0 if %total_games% lss %games_per_page% set /a total_pages=1

:: Print the header of the table
echo Game ID   Game Name                        Author              Created    Published     Views    Rating  Private
echo -------------------------------------------------------------------------------------------------------------------

:: Query and process the output for the current page
for /f "tokens=1,2,3,4,5,6,7,8* delims=|" %%A in ('curl -s "%API_SERVER%?type=get_games_by_gamename_type&gamename=%encoded_name%&game_type=%type%&games_per_page=%games_per_page%&offset=%offset%"') do (
    set "id=%%A"
    set "name=%%B"
    set "author=%%C"
    set "created=%%D"
    set "published=%%E"
    set "views=%%F"
    set "rating=%%G"
    :: Extract date from the datetime (first 10 characters)
    set "created_date=!created:~0,10!"
    set "published_date=!published:~0,10!"

    :: Replace 0000-00-00 with "unpublished"
    if "!published_date!"=="0000-00-00" set "published_date=Unpublished"

    :: Convert 1/0 to Yes/No
    if %%H==1 (set "private=Yes") else (set "private=No")

    :: Pad the fields to ensure alignment
    set "padded_id=        !id! "
    set "padded_name=!name!                                "
    set "padded_author=!author!                                                                    "
    set "padded_created=!created_date!              "
    set "padded_published=!published_date!          "
    set "padded_views=  !views!                 "
    set "padded_private=!private!                   "
    set "padded_rating=  !rating!/5                 "

    :: Print the padded fields in the table with proper alignment
    echo !padded_id:~-8!  !padded_name:~0,30!  !padded_author:~0,17!  !padded_created:~0,10!  !padded_published:~0,11! !padded_views:~0,8! !padded_rating:~0,10! !padded_private:~0,4!
)

goto bottombar


:usernameselect
cls
echo 0 - Back
echo ------------------------------------------------------------------------------------------------------------------
set /p "username=Enter Username: "

if "%username%"=="0" goto searchtypeselect

:: Convert the username to lowercase

:: Initialize an empty lowercase string
set "lowercase="

:: Loop through each character in the input string
for /l %%i in (0,1,255) do (
    set "char=!username:~%%i,1!"
    if defined char (
        call :tolower !char!
        set "lowercase=!lowercase!!char!"
    ) else (
        goto :done
    )
)

:done
set "username=%lowercase%"
:: Check if the username has any games
for /f "tokens=1" %%G in ('curl -s "%API_SERVER%?type=count_games_by_username&username=%username%"') do (
    set /a game_count=%%G
)

if %game_count%==0 (
    goto nogamesusername
)

:gametype
cls

:: Initialize variables
set "found_game_types=0"
set "counter=0"

:: Clear previous mappings
for %%A in (1 2 3 4 5 6 7 8 9) do set "type_option%%A="

:: Fetch distinct game types for the entered username
echo Available game types for %username%:
echo ------------------------------------------------------------------------------------------------------------------
:: Loop through the game types and assign sequential numbers
for /f "delims=" %%T in ('curl -s "%API_SERVER%?type=get_gametypes_by_username&username=%username%"') do (
    set /a counter+=1
    set "type_option!counter!=%%T"

    if "%%T"=="2" (
        echo !counter! - Platformer
        set /a current_page=1
    ) else if "%%T"=="1" (
        echo !counter! - Shooter
        set /a current_page=1
    ) else if "%%T"=="5" (
        echo !counter! - Physics
        set /a current_page=1
    ) else if "%%T"=="3" (
        echo !counter! - Algorithm Crew
        set /a current_page=1
    ) else if "%%T"=="7" (
        echo !counter! - Arcade
        set /a current_page=1
    ) else (
        set /a counter-=1
    )
)

:: Check if any game types were found
if %counter%==0 (
    goto nogamesusername
)

echo 0 - Back
:: Prompt the user for input
echo ------------------------------------------------------------------------------------------------------------------
set /p "choice=Enter Game Type: "

:: Handle going back
if "%choice%"=="0" goto usernameselect

:: Validate the user input and map it to the correct game type
set "valid_choice=0"
for /l %%N in (1,1,%counter%) do (
    if "%choice%"=="%%N" (
        set "type=!type_option%%N!"
        set "valid_choice=1"
    )
)

:: If input is invalid, prompt again
if "%valid_choice%"=="0" (
    echo Invalid choice! Press any key to try again...
    pause >nul
    goto gametype
)

goto printtableusername

:printtableusername
cls
:: Calculate offset based on current page
set /a offset=(%current_page%-1)*%games_per_page%

:: Get total number of games to calculate total pages
for /f "tokens=1" %%G in ('curl -s "%API_SERVER%?type=count_games_by_username_type&username=%username%&game_type=%type%"') do (
    set /a total_games=%%G
)

:: Calculate total pages
set /a total_pages=(%total_games% + %games_per_page% - 1) / %games_per_page%
if %total_games% lss %games_per_page% set /a total_pages=1
if %total_games% gtr 0 if %total_games% lss %games_per_page% set /a total_pages=1

:: Print the header of the table
echo  Game ID  Game Name                              Created      Published  Last Edited   Views  Rating  Private
echo -----------------------------------------------------------------------------------------------------------------

:: Query and process the output for the current page
for /f "tokens=1,2,3,4,5,6,7* delims=|" %%A in ('curl -s "%API_SERVER%?type=get_games_by_username_type&username=%username%&game_type=%type%&games_per_page=%games_per_page%&offset=%offset%"') do (
    set "id=%%A"
    set "name=%%B"
    set "created=%%C"
    set "published=%%D"
    set "edited=%%E"
    set "views=%%F"
    set "rating=%%G"
    :: Extract date from the datetime (first 10 characters)
    set "created_date=!created:~0,10!"
    set "published_date=!published:~0,10!"
    set "edited_date=!edited:~0,10!"

    :: Replace 0000-00-00 with "unpublished"
    if "!published_date!"=="0000-00-00" set "published_date=Unpublished"
    if "!edited_date!"=="!created_date!" set "edited_date=Unedited"

    :: Convert 1/0 to Yes/No
    if %%H==1 (set "private=Yes") else (set "private=No")

    :: Pad the fields to ensure alignment
    set "padded_id=        !id!"
    set "padded_name=!name!                                "
    set "padded_created=!created_date!              "
    set "padded_published=!published_date!          "
    set "padded_edited=!edited_date!                "
    set "padded_views=  !views!                 "
    set "padded_private=!private!                   "
    set "padded_rating=  !rating!/5                 "

    :: Print the padded fields in the table with proper alignment
    echo !padded_id:~-8!  !padded_name:~0,35!  !padded_created:~0,12!  !padded_published:~0,11!  !padded_edited:~0,10! !padded_views:~0,8! !padded_rating:~0,10! !padded_private:~0,4!
)

goto bottombar

:playgame
cls

:: Get published game date first_publish_date
for /f "delims=" %%D in ('curl -s "%API_SERVER%?type=get_publish_date&game_id=%input%"') do (
    set "publish_date_temp=%%D"
)

:: Check if the date is empty or invalid
if "%publish_date_temp%"=="0000-00-00 00:00:00" (
    set "playtype=saved"
) else (
:playgamequestion
cls
echo How do you want to play the game?
echo 1 - As it was last saved ^(usually more up to date^)
echo 2 - As it was published
echo 0 - Back
echo ------------------------------------------------------------------------------------------------------------------
set /p "playtype=Enter Type: "


if "!playtype!"=="1" (
    set "playtype=saved"
) else if "!playtype!"=="2" (
    set "playtype=published"
) else if "!playtype!"=="0" (
    if %searchtype%==1 goto printtableusername
    if %searchtype%==2 goto printtablegamename
) else (
    echo Invalid choice! Press any key to try again...
    pause >nul
    goto playgamequestion
)

)
cls

:: Default: if a game ID is entered, process it
curl -s "%API_SERVER%?type=get_game_data&game_id=%input%&playtype=%playtype%" > htdocs\game.xml

:: Fetch difficulty and rating for the selected game
for /f "tokens=1,2,3,4 delims=|" %%D in ('curl -s "%API_SERVER%?type=get_game_details&game_id=%input%"') do (
    set "difficulty=%%D"
    set "rating=%%E"
    set "gametype=%%F"
    set "author=%%G"
)

:: If rating is 0.0, set it to 3.0
if "!rating!"=="0.0" set "rating=3.0"

:: Write the gamedata.html file with the username, difficulty, and rating
echo ^&username=!author!^&difficulty=!difficulty!^&rating=!rating! > htdocs\php\getgamedata.html

:: Remove newlines when saving leaderboard
(
    for /f "delims=" %%A in ('curl -s "%API_SERVER%?type=get_leaderboard&game_id=%input%"') do (
        set /p result=%%A<nul
    )
) > htdocs\php\getleaderboard-shooter.html

echo Attempting to play the game^^!
echo Game not working? Please make sure your entered the correct game ID and try the other format.
echo Still not working? Please make sure you have port 80 not already bound^^!
start /b lighttpd.exe > nul 2>&1
start /w htdocs\flashplayer_sa.exe "http://localhost/fullgame!gametype!.swf?s=%RANDOM%&nocache=%RANDOM%"
cls
echo Shutting down integrated web server...
taskkill /F /IM lighttpd.exe > nul
if %searchtype%==1 goto printtableusername
if %searchtype%==2 goto printtablegamename

:viewdescription
cls
set "id=%input:~0,-5%"

:: Capture the description output
set "description="
for /f "delims=" %%D in ('curl -s "%API_SERVER%?type=get_game_description&game_id=%id%"') do (
    set "description=%%D"
)

:: Check if the description is empty
if not defined description (
    echo No description found for game ID %id%.
) else (
    echo Description:
    echo.
    echo %description%
)

goto backmsg

:viewtags
cls
set "id=%input:~0,-5%"

set "tags="
for /f "delims=" %%T in ('curl -s "%API_SERVER%?type=get_game_tags&game_id=%id%"') do (
    set "tags=%%T"
)


if not defined tags (
    echo No tags found for game ID %id%.
) else (
    echo Tags:
    echo.
    set "tags=!tags:,= !"
    echo !tags!
)

goto backmsg

:nogamesusername

echo No games found for username "%username%".
echo Please enter a different username.
echo Press any key to try again...
pause >nul
goto usernameselect


:nogamesgamename

echo No games found for the search "%gamename%".
echo Please enter a different search.
echo Press any key to try again...
pause >nul
goto gamenameselect

:backmsg
echo.
echo Press any key to go back...
pause >nul
if "%searchtype%"=="1" goto printtableusername
if "%searchtype%"=="2" goto printtablegamename

:bottombar
echo ------------------------------------------------------------------------------------------------------------------
echo id      - Play the game with the specified ID (eg: 1)                         ^| Double left click and double
echo id-desc - View the description of the game with the specified ID (eg: 1-desc) ^| right click on the ID to enter it
echo id-tags - View the tags of the game with the specified ID (eg: 1-tags)        ^| automatically
echo pg-page - Change the number of games per page (eg: 10-page)                   ^| 
echo next    - Go to the next page                                                 ^| Press ctrl+F to search
echo prev    - Go to the previous page                                             ^| 
echo 0       - Go back                                                             ^| Page: %current_page%/%total_pages%         
echo ------------------------------------------------------------------------------------------------------------------

:: Prompt for user input to navigate
set /p "input=Enter Command: "

:: Handle different commands
if "%input%"=="0" (
    if "%searchtype%"=="1" goto gametype
    if "%searchtype%"=="2" goto gametypegamename
)

:: Check if next page is available
if "%input%"=="next" (
    if %current_page% lss %total_pages% (
        set /a current_page+=1
        if "%searchtype%"=="1" goto printtableusername
        if "%searchtype%"=="2" goto printtablegamename
    ) else (
        echo You are already on the last page. Press any key to continue.
        pause >nul
        if "%searchtype%"=="1" goto printtableusername
        if "%searchtype%"=="2" goto printtablegamename
    )
)

:: Check if previous page is available
if "%input%"=="prev" (
    if %current_page% gtr 1 (
        set /a current_page-=1
        if "%searchtype%"=="1" goto printtableusername
        if "%searchtype%"=="2" goto printtablegamename
    ) else (
        echo You are already on the first page. Press any key to continue.
        pause >nul
        if "%searchtype%"=="1" goto printtableusername
        if "%searchtype%"=="2" goto printtablegamename
    )
)

:: Description (check if ends with -desc)
if "%input:~-5%"=="-desc" goto viewdescription
if "%input:~-5%"=="-tags" goto viewtags

if "%input:~-5%"=="-page" (
    set "games_per_page=%input:~0,-5%"
    if "%searchtype%"=="1" goto printtableusername
    if "%searchtype%"=="2" goto printtablegamename
)

goto playgame


:: I'm sorry, I had to do this
:tolower
:: Check if the provided character is uppercase and map it to lowercase
set "char=%1"
if "%char%"=="A" set "char=a"
if "%char%"=="B" set "char=b"
if "%char%"=="C" set "char=c"
if "%char%"=="D" set "char=d"
if "%char%"=="E" set "char=e"
if "%char%"=="F" set "char=f"
if "%char%"=="G" set "char=g"
if "%char%"=="H" set "char=h"
if "%char%"=="I" set "char=i"
if "%char%"=="J" set "char=j"
if "%char%"=="K" set "char=k"
if "%char%"=="L" set "char=l"
if "%char%"=="M" set "char=m"
if "%char%"=="N" set "char=n"
if "%char%"=="O" set "char=o"
if "%char%"=="P" set "char=p"
if "%char%"=="Q" set "char=q"
if "%char%"=="R" set "char=r"
if "%char%"=="S" set "char=s"
if "%char%"=="T" set "char=t"
if "%char%"=="U" set "char=u"
if "%char%"=="V" set "char=v"
if "%char%"=="W" set "char=w"
if "%char%"=="X" set "char=x"
if "%char%"=="Y" set "char=y"
if "%char%"=="Z" set "char=z"
exit /b