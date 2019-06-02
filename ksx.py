#!/usr/local/bin/python3
"""A transpilation and minification tool for KerboScript (Extended)"""

# https://stackoverflow.com/questions/952914/how-to-make-a-flat-list-out-of-list-of-lists
flatten = lambda l: [item for sublist in l for item in sublist]


def min_strip_comments(file_lines):
    """Comments are only needed for weak Kerbals, remove them"""
    def comment_filter(line):
        found_comment = line.find("//")
        return found_comment >= 0, found_comment

    return_lines = []

    for line in file_lines:
        found, start = comment_filter(line)
        if not found or (found and start > 0):
            if start >= 0:
                return_lines.append(line[0:start])
            else:
                return_lines.append(line[0:])

    return return_lines


def min_remove_whitespace(file_lines):
    """whitespace is only needed for weak Kerbals, remove them"""
    return (l.strip() for l in file_lines)


def min_remove_blank_lines(file_lines):
    """Blank lines are only needed for weak Kerbals, remove them"""
    return (l for l in file_lines if l.strip())


def min_squash_to_oneline(file_lines):
    return "".join(file_lines)


def min_remove_useless_space(file_oneline):
    quote_chars = ["'", '"']
    operators = [",", "*", "/", "^", "+", "-"]

    # iterate over each character of the line and track if we are inside a
    # string, if not we can remove any spaces surrounding this operator
    space_locations = []
    operator_locations = []
    string_nest_depth = [0, []]

    for i, char in enumerate(file_oneline):
        # if we found a string character, increase depth or decrease depending
        # on what we were expecting to find
        #
        # this won't actually work if you have "'" or '"'
        #
        # both are valid strings, but won't parse correctly here, I don't think
        # I have any strings like that at the moment, can deal with it when it
        # happens
        if char in quote_chars:
            if string_nest_depth[0] and char != string_nest_depth[1][-1]:
                string_nest_depth[0] = string_nest_depth[0] + 1
                string_nest_depth[1].append(char)
            elif string_nest_depth[0]:
                string_nest_depth[0] = string_nest_depth[0] - 1
                string_nest_depth[1].pop()
            continue

        # save indices of space characters
        if char == " " and not string_nest_depth[0]:
            space_locations.append(i)
            continue

        # save indices of operator characters
        if char in operators and not string_nest_depth[0]:
            operator_locations.append(i)
            continue

    # find strides where an operator is surrounded by spaces
    space_strides = []
    for op in operator_locations:
        first_space, last_space = op, op

        # search forward for spaces
        for char in file_oneline[op + 1:]:
            if char != " ":
                break
            last_space += 1

        # search backward for spaces
        for char in reversed(file_oneline[0:op]):
            if char != " ":
                break
            first_space -= 1

        # if we found a surrounding space, mark it as a stride
        if first_space != op or last_space != op:
            fs = first_space if first_space is not op else op + 1
            ls = last_space if last_space is not op else op -1
            space_strides.append((fs, ls))

    # strides can be flattened to simply a list of indexes of space characters to filter out
    remove_indices = [
        x for x in
        flatten(map(lambda x: range(x[0], x[1] + 1), space_strides))
        if x not in operator_locations]

    # create a new string with all operator-space strides removed
    return "".join(c for (i, c) in enumerate(file_oneline) if i not in remove_indices)


def ksx_remove_lines(file_lines):
    return (l for l in file_lines if not l.strip().startswith("@ksx"))


def ensure_space_after_certain_statements(file_oneline):
    # `parameter` and `set` statements both require a space after their closing
    # period (or maybe before they start?)
    #
    # TODO: This isn't implemented, nor is it being used
    pass


def walkpath_with_action(path, action):
    from os import walk

    acc = []
    for dirpath, dirnames, filenames in walk(path):
        acc.append(action(dirpath, dirnames, filenames))

    return acc


def find_all_ks_files(root_folder):
    """Find all files with a .ks extension in a given folder"""
    def file_action(dirpath, dirnames, filenames):
        from os.path import join

        acc = []
        for filename in (f for f in filenames if (f.endswith(".ks") or f.endswith(".ksx"))):
            acc.append(join(dirpath, filename))

        return acc

    return flatten(walkpath_with_action(root_folder, file_action))


def remove_directory_if_empty(directory):
    import os
    import errno

    try:
        os.rmdir(directory)
    except OSError as e:
        if e.errno == errno.ENOTEMPTY:
            pass


def nuke_minified_directory():
    """Remove everything in the minify directory that isn't tracked by git"""
    whitelist = ["README.md"]

    def remove_if_not_whitelisted(dirpath, dirnames, filenames):
        import os

        from os.path import join

        local_whitelist = [join(dirpath, x) for x in whitelist]
        for filename in (f for f in filenames if f not in whitelist + local_whitelist):
            os.remove(join(dirpath, filename))

        remove_directory_if_empty(dirpath)

    walkpath_with_action("./minified/", remove_if_not_whitelisted)


def compile_single_file(file_path, minifier_actions, transpile_only=False, safe_only=True):
    import os
    import shutil

    basepath, basename = [f(file_path) for f in (os.path.dirname, os.path.basename)]
    root_no_source = os.path.join(*os.path.relpath(basepath).split('/')[1:])
    basename = "{}.ks".format(os.path.splitext(basename)[0])

    # minified files must match directory structure of files in source, ensure directories exist
    dest_dir = os.path.join("./minified", root_no_source)
    dest_path = os.path.join(dest_dir, basename)
    os.makedirs(dest_dir, exist_ok=True)

    with open(file_path, 'r') as rf:
        file_lines = rf.readlines()

    def allowed_filter(func, tags):
        return not (
            (safe_only and "safe" not in tags) or
            (transpile_only and "transpile-only" not in tags))

    allowed_actions = {
        k: [x for x in v if allowed_filter(*x)]
        for (k, v) in minifier_actions.items()
    }

    for action_function, action_tags in allowed_actions["linewise"]:
        file_lines = action_function(file_lines)

    file_oneline = min_squash_to_oneline(file_lines)

    for action_function, action_tags in minifier_actions["oneline"]:
        file_oneline = action_function(file_oneline)

    with open(dest_path, 'w') as wf:
        wf.write(file_oneline)

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser("ksx: KerboScript Extended transpiler")
    parser.add_argument("--nuke",
                        action='store_true',
                        help="Clean out the 'minified' directory")

    parser.add_argument("--transpile-only",
                        action="store_true",
                        help="Only perform transpilation from .ks to .ksx, no further optimizations")

    parser.add_argument("--safe",
                        action='store_true',
                        help=("Perform just a safe subset of the minification routines, "
                              "this will only use routines which have proven to be safe "
                              "in actual operation."))

    parser.add_argument("--single-file",
                        help="Specify a single file to transpile")

    parser.add_argument("--all-files",
                        action='store_true',
                        help="Transpile all .ks & .ksx files in the source directory")

    args = parser.parse_args()

    transpiler_actions = {
        "oneline": [
            [min_remove_useless_space, []]
        ],
        "linewise": [
            [min_strip_comments, ["safe"]],
            [min_remove_blank_lines, ["safe"]],
            [min_remove_whitespace, []],
            [ksx_remove_lines, ["transpile-only", "safe"]]
        ],
    }

    if args.nuke:
        nuke_minified_directory()

    if args.single_file:
        files_to_compile = [args.single_file]
    elif args.all_files:
        files_to_compile = find_all_ks_files("./source/")

    for single_file in files_to_compile:
        compile_single_file(
            single_file,
            transpiler_actions,
            transpile_only=args.transpile_only,
            safe_only=args.safe,
        )
