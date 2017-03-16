# Articles

# Hide all outputs and show only echo messages
http://stackoverflow.com/questions/18351198/what-are-the-uses-of-the-exec-command-in-shell-scripts
http://stackoverflow.com/a/30717628/1470127
http://stackoverflow.com/questions/818255/in-the-shell-what-does-21-mean

exec 7>&1
exec >/dev/null 2>&1  # Output of all commands + stderr output goes to /dev/null
ls # No output shown
echo "My message" >&7


The output of all the commands were really messy (and unnecessary because user only wants to know if everything went fine or not), so I wanted to only show echo messages and hide everything else. So, I followed the snippet mentioned here. http://stackoverflow.com/a/30717628/1470127.

"7>&1" command basically says that redirect all the output on &7 to stdout (&1) and "exec" copies the file descriptor &1 to &7 (http://stackoverflow.com/questions/18351198/what-are-the-uses-of-the-exec-command-in-shell-scripts). 
The next command "exec >/dev/null" redirects the output of each command to /dev/null. But since I want to show some echo messages, I use the old saved stdout to print them e.g. echo "test" >&7.

In the end, I am new to this and my understanding is limited. Apparently, it works as expected.
