require 'yaml'
require 'open3'
require 'find'
require 'fileutils'
require 'pathname'

def get_env_variable(key)
	return (ENV[key] == nil || ENV[key] == "") ? nil : ENV[key]
end

repo_path = get_env_variable("AC_REPOSITORY_DIR") || abort('Missing AC_REPOSITORY_DIR variable.')
temp_folder = get_env_variable("AC_TEMP_DIR") || abort('Missing AC_TEMP_DIR variable.')
smartface_cli_version = get_env_variable("AC_SMARTFACE_CLI_VERSION") || "latest"
smartface_player_version = get_env_variable("AC_SMARTFACE_PLAYER_VERSION") || "latest"

def run_command(command)
    puts "@@[command] #{command}"
    status = nil
    stdout_str = nil
    stderr_str = nil

    Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
        stdout.each_line do |line|
            puts line
        end
        stdout_str = stdout.read
        stderr_str = stderr.read
        status = wait_thr.value
    end

    unless status.success?
        puts stderr_str
        raise stderr_str
    end
end

# Install smartface cli
run_command("yarn  global add  smartface@#{smartface_cli_version}")
run_command("smfc -v")
# Specify player version
run_command("smfc use #{smartface_player_version} --os Android")
# Install dependencies
run_command("cd #{repo_path}/scripts && npm i")
run_command("cd #{repo_path} && npm i && npm run build:transpile")

params = "--task=export:Android --projectRoot=#{repo_path} --outputFolder=#{temp_folder}/sf-android-temp"
run_command("smfc #{params}")

ac_variants = "PlayerProdRelease"
ac_module = "app"
ac_project_path = "#{temp_folder}/sf-android-temp/SmartfaceAndroid"

puts "Exporting AC_PROJECT_PATH=#{ac_project_path}"
puts "Exporting AC_VARIANTS=#{ac_variants}"
puts "Exporting AC_MODULE=#{ac_module}"

open(ENV['AC_ENV_FILE_PATH'], 'a') { |f|
    f.puts "AC_PROJECT_PATH=#{ac_project_path}"
    f.puts "AC_VARIANTS=#{ac_variants}"
    f.puts "AC_MODULE=#{ac_module}"
}

exit 0
