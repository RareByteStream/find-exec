#!/usr/bin/env bash

# LEGAL NOTICE  
# 
# Copyright (c) 2026 Alex Willer (Legal: Enes Güleç)
# (GH: RareByteStream) <enesg.devel@gmail.com> All rights reserved.
# 
# This work is licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#    http://www.apache.org/licenses/LICENSE-2.0
#    https://www.apache.org/licenses/LICENSE-2.0.txt
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.




function find-exec () {

  ## PHASE: Setup
  
  local -r version="0.0.0"

  local usages=$'\n\r'"    Usage Mode Examples:"$'\n\r'
  usages+="     find-exec NAME <regular-mode-options>"
  usages+=$'\n\r'"     find-exec --help"$'\n\r'
  usages+="     find-exec --deps/--dependencies"$'\n\r'
  usages+="     find-exec --usage/--usages"$'\n\r'
  usages+="     find-exec --version"$'\n\r'
  readonly usages
  
local -r help="

    exec-find, version $version
    Find the absolute path of an executable file or 
    symlink named as NAME from given directory paths.
    
$usages
  
    Options which provide paths to search in:
    
      Paths are provided as seperated by ':' 
      and merged into the option key with '='
      Example: '--paths=/usr/bin:/bin'.
      
      --paths	   Sets the list of directories to search in. 
                   Default value is a copy of \$PATH.
                   
      --appends    Put the given paths at the end of list.
      
      --prepends   Insert the given paths at beginning of the list.
      


    Options which determine the search behavior:
    
      --canonical        Canonicalize the result without 
                         resolving parent directory symlinks.
    
      --physical         Canonicalize the result with 
                         parent directory symlinks resolved 
                         to their real target.

      --max-follows=N    Limit the amount of symlinks followed to N
                         when the found executable is a symlink.
                         Cannot be less than 0, default value is 100.
                         Has to be a valid integer expression.
                         
                         

    Options which determine interface behavior:
    
      -s/--silent	     Do not output any errors.
      
      -i/--interactive	     Format the result to be readable 
                             before print it.
      
      -O/--no-stdout         Do not send the result to stdout 
                             if --interactive is not supplied.
      
      --declare-name=KEY     Declare or assign the result as the value of name KEY.
                             If name KEY exists in caller's scope, 
                             it is gonna be assigned to name in that scope; 
                             otherwise it is declared and assigned in global scope.
                             Not supplying a value with or without '=' sets the 
                             KEY to the default. Default KEY is '_found_exec_'.

      --help                 Display this usage manual and exit with code 0.

      --deps                 Check availability of dependencies,
                             print the information, exit with code 0 if all found, 
                             1 if at least one is not found.

      --usage/--usages       Print the usage patterns, exit with code 0.

      --version              Print the version, exit with code 0.



    Exit Statuses:
      0 -> found the executable file
      1 -> terminated due to invalid option(s)
      2 -> invalid intermediate or final path
      3 -> found it as a non-executable file


";



  local return_code=0
  local will_search=1
  local errors=()

  function _find_exec_error_ () {
    local -n errs="errors"
    local -n will="will_search"
    errs+=( "$1"$'\n\r' )
    will=1
    return 0
  }
  


  function _find_exec_merged_parse_ () {
    local -n rn_code="return_code"
    local -n def="defined"
    local -n vals="values"
    local -n map="mapped"
    local args="$1"
    local maxi=$(( ${#args} - 1 ))
    local index=-1
    local arg=""
    local key=""
    while (( $index < $maxi )); do
    
      index=$(( $index + 1 ))
      arg="${args:$index:1}"
      key="${map["$arg"]}"

      if (( ${#key} > 0 )); then
        if [[ ${def["$key"]} -eq 1 ]]; then
          _find_exec_error_ "Cannot pass $key twice"
          rn_code=1
        else
          if [[ "$arg" = "d" ]]; then
            vals["$key"]="_found_exec_"
          else
            vals["$key"]=1
          fi
        fi
        def["$key"]=1
      else
        _find_exec_error_ "Illegal option: $arg, in: \"-$args\""
        rn_code=1
      fi
      
    done
    return 0
  }
  
  
  
  ## PHASE: Mode Selection

  if [[ "${#@}" -eq 0 || "$1" = "--usage" || "$1" = "--usages" ]]; then
    printf "%s" "$usages"$'\n\r'
    return 255
  fi
  
  if [[ "$1" = "--help" ]]; then
    printf "%s" "$help"
    return 255
  fi
  
  if [[ "$1" = "--version" ]]; then
    printf "%s" "exec-find, version $version"
    return 255
  fi
  
  
  if [[ "$1" = "--deps" ]]; then
    local deps=( "printf" "find" "realpath" )
    local dep=""
    printf "%s" "Validating find-exec dependencies:"$'\n\r'
    local rc=0
    for dep in "${deps[@]}"; do
      if command -v $dep &>/dev/null; then
        printf "%s" "  \"$dep\" -> available"$'\n\r'
      else
        printf "%s" "  \"$dep\" -> not found"$'\n\r'
        local rc=1
      fi
    done
    printf "%s" "Done."$'\n\r'
    return $rc
  fi

  if [[ "$1" = "--version" ]]; then
    printf "%s" "$version"
    return 255
  fi
  

  local execname="$1"
  shift 1


  if [[ "$execname" = *"/"* || "$execname" = "." || "$execname" = ".." ]]; then
    _find_exec_error_ "Invalid executable name. Got: '$execname'"
    return_code=1
  fi

  
  
  ## PHASE: Parsing

  local paths=()
  local appends=()
  local prepends=()
  
  
  local -A mapped
  
  mapped["O"]="--no-stdout"
  mapped["C"]="--canonical"
  mapped["P"]="--physical"
  mapped["i"]="--interactive"
  mapped["s"]="--silent"
  mapped["d"]="--declare-name"
  
  local -A defined
  
  defined["--paths"]=0
  defined["--appends"]=0
  defined["--prepends"]=0
  
  defined["--max-follows"]=0
  defined["--declare-name"]=0
  
  defined["--no-stdout"]=0
  defined["--canonical"]=0
  defined["--physical"]=0
  defined["--interactive"]=0
  defined["--silent"]=0
  
  
  local -A values
  
  values["--max-follows"]=100
  values["--declare-name"]=""
  
  values["--no-stdout"]=0
  values["--canonical"]=0
  values["--physical"]=0
  values["--interactive"]=0
  values["--silent"]=0
  
  
  local curr=""
  local _data_=""
  
  local arg=""
  
  while (( ${#@} > 0 )); do
      local arg="$1"

      curr="--paths"
      if [[ "$arg" = "$curr="* ]]; then
        if [[ ${defined["$curr"]} -eq 1 ]]; then
          _find_exec_error_ "Cannot pass $curr twice"
          return_code=1
        fi
        _data_="${arg/"--paths="/""}"
        _data_="${_data_//":"/" "}"
        paths+=( ${_data_} )
        defined[$curr]=1
        shift 1 ; continue
      fi
      
      curr="--appends"
      if [[ "$arg" = "$curr="* ]]; then
        if [[ ${defined["$curr"]} -eq 1 ]]; then
          _find_exec_error_ "Cannot pass $curr twice"
          return_code=1
        fi
        _data_="${arg/"$curr="/""}"
        _data_="${_data_//":"/" "}"
        appends+=( ${_data_} )
        defined["$curr"]=1
        shift 1 ; continue
      fi
      
      curr="--prepends"
      if [[ "$arg" = "$curr="* ]]; then
        if [[ ${defined["$curr"]} -eq 1 ]]; then
          _find_exec_error_ "Cannot pass $curr twice"
          return_code=1
        fi
        _data_="${arg/"$curr="/""}"
        _data_="${_data_//":"/" "}"
        prepends+=( ${_data_} )
        defined["$curr"]=1
        shift 1 ; continue
      fi
      
      curr="--max-follows"
      if [[ "$arg" = "$curr="* ]]; then
        if [[ ${defined["$curr"]} -eq 1 ]]; then
          _find_exec_error_ "Cannot pass $curr twice"
          return_code=1
        fi
        _data_="${arg/"$curr="/""}"
        if [[ "$_data_" =~ ^[0-9]+$ ]]; then
          values["$curr"]="${_data_//" "/""}"
        else
          _find_exec_error_ "Invalid value given to $curr: \"$_data_\""
        fi
        defined["$curr"]=1
        shift 1 ; continue
      fi
      
      curr="--declare-name"
      if [[ "$arg" = "$curr"* || "$arg" = "-d" ]]; then
        if [[ ${defined["$curr"]} -eq 1 ]]; then
          _find_exec_error_ "Cannot pass $curr twice"
          return_code=1
        fi
        if [[ "$arg" = "$curr="* ]]; then
          _data_="${arg/"$curr="/""}"
          if [[ "$_data_" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            values[$curr]="$_data_"
          elif [[ "$_data_" = "" ]]; then
            values[$curr]="_found_exec_"
          else
            _find_exec_error_ "Invalid value given to --declare-name: \"$_data_\""
          fi
        elif [[ "$arg" = "$curr" ]]; then
          values[$curr]="_found_exec_"
        fi
        defined["$curr"]=1
        shift 1 ; continue
      fi
      
      curr="--no-stdout"
      if [[ "$arg" = "$curr" ]]; then
        if [[ ${defined["$curr"]} -eq 1 ]]; then
          _find_exec_error_ "Cannot pass $curr twice"
          return_code=1
        else
          values["$curr"]=1
          defined["$curr"]=1
        fi
        shift 1 ; continue
      fi
      
      curr="--canonical"
      if [[ "$arg" = "$curr" ]]; then
        if [[ ${defined["$curr"]} -eq 1 ]]; then
          _find_exec_error_ "Cannot pass $curr twice"
          return_code=1
        else
          values["$curr"]=1
          defined["$curr"]=1
        fi
        shift 1 ; continue
      fi
      
      curr="--physical"
      if [[ "$arg" = "$curr" ]]; then
        if [[ ${defined["$curr"]} -eq 1 ]]; then
          _find_exec_error_ "Cannot pass $curr twice"
          return_code=1
        else
          values["$curr"]=1
          defined["$curr"]=1
        fi
        shift 1 ; continue
      fi
      
      curr="--interactive"
      if [[ "$arg" = "$curr" ]]; then
        if [[ ${defined["$curr"]} -eq 1 ]]; then
          _find_exec_error_ "Cannot pass $curr twice"
          return_code=1
        else
          values["$curr"]=1
          defined["$curr"]=1
        fi
        shift 1 ; continue
      fi
      
      curr="--silent"
      if [[ "$arg" = "$curr" ]]; then
        if [[ ${defined["$curr"]} -eq 1 ]]; then
          _find_exec_error_ "Cannot pass $curr twice"
          return_code=1
        else
          values["$curr"]=1
          defined["$curr"]=1
        fi
        shift 1 ; continue
      fi
      
      if [[ "$arg" =~ ^[-][a-zA-Z]*$ ]]; then
        _find_exec_merged_parse_ "${arg:1:${#arg}}"
        shift 1 ; continue
      fi
      
      _find_exec_error_ "Illegal option: $arg"
      return_code=1
      shift 1

      
  done



  ## PHASE: Execution
  
  local paths_def=0
  local main_list=()
  
  local path=""
  local file=""

  local exec_path=""
  local exec_dir=""
  local execname_in=""
  
  local count=0
  local found=0
  local found2=0
  
  if [[ "$will_search" -eq 1 ]]; then
    
    (( ${#paths[@]} > 0 )) && paths_def=1
    
    if [[ $paths_def -eq 0 ]]; then
      paths=( ${PATH//":"/" "} )
    fi
    
    main_list=( "${prepends[@]}" "${paths[@]}" "${appends[@]}" )

    for path in "${main_list[@]}"; do
      file="$( find "$path" -type f -name "$execname" -o -type l -name "$execname" 2>/dev/null || printf "" )"
      file="${file//'\n'/""}"
      if [[ -f "$file" && -x "$file" ]]; then
        exec_path="$file"
        exec_dir="${exec_path%"/"*}"
        found=1
        break
      fi
    done
    
    if (( $found == 0 )); then
      _find_exec_error_ "Could not find any executable file in directories."
      return_code=2
    fi
    
    (( $found == 1 )) && while (( $count < ${values["--max-follows"]} )); do

       exec_dir="${exec_path%"/"*}"
       execname_in="${exec_path/$exec_dir/""}"
       execname_in="${execname_in/"/"/""}"

       if [[ -L "$exec_path" ]]; then
       
         exec_path="$( readlink -s "$exec_path" 2>/dev/null || printf "" )"
         [[ "$exec_path" = *"/" ]] && exec_path="${exec_path:0:${#exec_path}-1}"

         found2=1
         
         if [[ ! "$exec_path" = "/"* ]]; then
           exec_path="$exec_dir/$exec_path"
         fi
         
       elif [[ ! -f "$exec_path" ]]; then
       
         _find_exec_error_ "Resolved link path doesn't point to a file. Got: '$exec_path'"
         return_code=2
         found2=0
         break
         
       fi


       count=$(( $count + 1 ))

    done

    

    
    local path_in=""
    if (( $found2 == 1 )) && (( ${values["--physical"]} == 1 )); then
    
      local path_in="$( realpath -ePq "$exec_dir" 2>/dev/null || printf "" )"
      if [[ -d "$path_in" ]]; then
        exec_dir="$path_in"
        exec_path="$exec_dir/$execname_in"
      else
        _find_exec_error_ "Resolved directory path doesn't exist in file-system. Got: '$path_in'"
        exec_path=""
        return_code=2
      fi
      
    else
    
      if (( $found2 == 1 )) && (( ${values["--canonical"]} == 1 )); then
        local path_in="$( realpath -eLq "$exec_dir" 2>/dev/null || printf "" )"
        if [[ -d "$path_in" ]]; then
          exec_dir="$path_in"
          exec_path="$exec_dir/$execname_in"
        else
          _find_exec_error_ "Resolved directory path doesn't exist in file-system. Got: '$path_in'"
          exec_path=""
          return_code=2
        fi
      fi
    
    fi
    
    
  fi




  
  if [[ "$return_code" -eq 0 && "${#values["--declare-name"]}" -gt 0 ]]; then
    local -n ref_in="${values["--declare-name"]}"
    ref_in="$exec_path" 
  fi


  if (( ${values["--no-stdout"]} == 0 )) || (( ${values["--interactive"]} == 1 )); then
    local printed="$exec_path"
    if [[ ${values["--interactive"]} -eq 1 ]]; then
      printed="'$printed'"$'\n\r'
    fi
    printf "%s" "$printed" >&1
  fi
  


  ## PHASE: Error Reporting
  
  local error=""
  if (( ${values["--silent"]} == 0 )); then
    for error in "${errors[@]}"; do
      printf "%s" "find-exec: ""$error" >&2
    done
  fi


  unset -f _find_exec_error_
  unset -f _find_exec_merged_parse_
  return $return_code


}


if [[ "$0" = "${BASH_SOURCE[0]}" ]]; then
  find-exec "$@"
fi


