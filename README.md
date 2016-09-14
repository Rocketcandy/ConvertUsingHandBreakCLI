# ConvertUsingHandBreakCLI
Powershell Script to automate conversion of video files a specified size or larger to smaller mkv or mp4 files.

# Pre Reqs
1. Must have HandBreak(64-bit) installed.  You can get it here: <https://handbrake.fr/downloads.php>
2. Must have powershell setup to allow this script.  See [Powershell Setup](https://github.com/Rocketcandy/ConvertUsingHandBreakCLI#powershell-setup)
3. Powershell is a requirement to run the script.  I have only tested it on Windows, but if you can get it to work on MacOS or Linux more power to you!
4. Edit the script and change the first section of the script to match your needs

A couple notes about editing the script

1. All paths can be either a network path. example: "\\\\my.server\share\files"
2. Or a local path. example: "C:\Users\Public\Videos"
3. Just make sure that whatever path you use it stays inside the quotes.
 

# Running the script
1. After you have modified the variables and changed the execution policy right click on the script
2. Select Run with Powershell
3. You should see a Powershell window apear and you should see this apear at the top of the window:

    Finding Movie Files over xGB in \\\\Path\To\Movies and Episodes ove xGB in \\\\Path\To\Shows be patient...

4. If you see that message the script is running and conversions should start

# Powershell Setup
The easiest way to do this is to allow this script to run by using this command in powershell running as admin:

    Set-ExecutionPolicy Unrestricted

Select Yes to all when prompted

for more information on Execution Policy view this page: <https://technet.microsoft.com/library/hh847748.aspx>

# License

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
