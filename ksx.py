#!/usr/local/bin/python3
"""A transpilation and minification tool for KerboScript (Extended)"""

# https://stackoverflow.com/questions/952914/how-to-make-a-flat-list-out-of-list-of-lists
flatten = lambda l: [item for sublist in l for item in sublist]


class ImportFileNotFoundError(FileNotFoundError):
    """Raised when an import statement cannot be expanded"""
    pass


class ImportNotFoundError(ImportError):
    """Raised when a from import statement fails to find specified function in given files"""
    pass


def min_strip_comments(file_lines, *args, **kwargs):
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


def min_remove_whitespace(file_lines, *args, **kwargs):
    """whitespace is only needed for weak Kerbals, remove them"""
    return (l.strip() for l in file_lines)


def min_remove_blank_lines(file_lines, *args, **kwargs):
    """Blank lines are only needed for weak Kerbals, remove them"""
    return (l for l in file_lines if l.strip())


def min_squash_to_oneline(file_lines, *args, **kwargs):
    """Translate list of lines to a single line"""
    return " ".join(file_lines)


def min_remove_useless_space(file_oneline):
    """Remove any extra spacing around things that don't have spacing requirements"""
    quote_chars = ["'", '"']
    operators = [",", "*", "/", "^", "+", "-"]

    # bracketsen can also be reduced in the same way as operators are
    operators += ["{", "}", "(", ")", "[", "]"]

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


def ksx_expand_import(file_lines, include_files, *args, **kwargs):
    """Expand @ksx import statements to full file (not @ksx from...)"""
    def parse_ksx_import_statement(line):
        import re

        import_match_re = re.compile(r"@ksx import \((.*)\).")
        re.IGNORECASE = True

        return [l.strip().replace('"', '').replace("'", '')
                for l in import_match_re.match(line).group(1).split(',')]

    def match_statement_to_include_files(import_string, include_files):
        # just doing a partial substring match, that's sufficient for my needs
        # at the moment
        acc = []
        for imp in import_string:
            for f in include_files:
                if imp in f:
                    acc.append(f)
                    break

        if acc: return acc
        raise ImportFileNotFoundError("Could not match import statement to include path")

    acc, lineno = [], 0
    for l in file_lines:
        if line_has_ksx_directive(l) and l.split()[1].lower() == "import":
            stmt = parse_ksx_import_statement(l)
            for imp_file_path in match_statement_to_include_files(stmt, include_files):
                with open(imp_file_path, 'r') as imp_file:
                    import_lines = imp_file.readlines()
                    acc = acc[:lineno] + import_lines + acc[lineno:]
                    lineno += len(import_lines)
        else:
            acc.append(l)
            lineno += 1

    return acc


def ksx_expand_from_import(file_lines, include_files, *args, **kwargs):
    """Expand @ksx from (x) import (y) statements to function inlining"""
    def parse_ksx_import_statement(line):
        import re

        import_match_re = re.compile(r"@ksx from \((.*)\) import \((.*)\).")
        re.IGNORECASE = True

        matches = import_match_re.match(line)

        if matches:
            files = [l.strip().replace('"', '').replace("'", '')
                     for l in matches.group(1).split(',')]
            functions = [l.strip().replace('"', '').replace("'", '')
                         for l in matches.group(2).split(',')]

            return files, functions
        else:
            return [], []

    def match_statement_to_include_files(import_string, include_files):
        # just doing a partial substring match, that's sufficient for my needs
        # at the moment
        acc = []
        for imp in import_string:
            for f in include_files:
                if imp in f:
                    acc.append(f)
                    break

        if acc: return acc
        raise ImportFileNotFoundError("Could not match import statement to include path")

    def function_from_file(file_lines, function_name):
        function_start_index = None
        closing_bracket_index = None
        bracket_stack = 0

        acc = []

        for lineno, line in enumerate(file_lines):
            if line.strip().startswith('function {} '.format(function_name)):
                function_start_index = lineno

            if function_start_index is not None:
                acc.append(line)
                bracket_stack += (line.count('{') - line.count('}'))

                if closing_bracket_index is None and '}' in line and bracket_stack == 0:
                    closing_bracket_index = lineno

            if closing_bracket_index is not None:
                return acc

    def function_from_files(include_files, function_name):
        for f in include_files:
            with open(f, 'r') as fp:
                fff = function_from_file(fp.readlines(), function_name)
                if fff is not None:
                    return fff

    acc, lineno = [], 0
    for l in file_lines:
        if line_has_ksx_directive(l) and l.split()[1].lower() == "from":
            files, functions = parse_ksx_import_statement(l)
            files = [match_statement_to_include_files(fp, include_files) for fp in files]
            for func in functions:
                func_from_files = function_from_files(include_files, func)
                if func_from_files is None:
                    msg = "Could not find {} in files {}".format(func, files)
                    raise ImportNotFoundError(msg)

                acc = acc[:lineno] + func_from_files + acc[lineno:]
                lineno += len(func_from_files)
        else:
            acc.append(l)
            lineno += 1

    return acc


def ksx_remove_lines(file_lines, *args, **kwargs):
    """Remove any remaining @ksx lines, this is the last ksx rule executed"""
    return (l for l in file_lines if not l.strip().startswith("@ksx"))


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


def file_has_ksx_extension(file_path):
    import os
    return os.path.splitext(file_path)[1] == ".ksx"


def line_has_ksx_directive(file_line, specifically=None):
    return file_line.strip().startswith(
        "@ksx" if specifically is None else "@ksx {}".format(specifically))


def file_has_ksx_directive(file_lines, specifically=None):
    return any(line_has_ksx_directive(l, specifically) for l in file_lines)


def compile_single_file_lines(file_lines, minifier_actions,
                              transpile_only=False,
                              safe_only=True,
                              include_paths=None,
                              **kwargs):
    # include_paths needs to be a list of directories, if it is coming in with
    # the default value of None then there are no included dirs
    if include_paths is None:
        include_paths = []

    include_files = flatten(find_all_ks_files(p) for p in include_paths)

    def allowed_filter(func, tags):
        return not (
            (safe_only and "safe" not in tags) or
            (transpile_only and "transpile-only" not in tags))

    allowed_actions = {
        k: [x for x in v if allowed_filter(*x)]
        for (k, v) in minifier_actions.items()
    }

    for action_function, action_tags in allowed_actions["linewise"]:
        file_lines = action_function(file_lines, include_files)

    if not transpile_only:
        file_oneline = min_squash_to_oneline(file_lines)
        for action_function, action_tags in allowed_actions["oneline"]:
            file_oneline = action_function(file_oneline)
    else:
        file_oneline = "".join(file_lines)

    return file_oneline


def compile_single_file(file_path, minifier_actions, **kwargs):
    import os
    import shutil

    file_path = os.path.abspath(file_path)
    basepath, basename = [f(file_path) for f in (os.path.dirname, os.path.basename)]
    split_path = os.path.relpath(basepath).split('/')

    if split_path[0] == "source":
        root_no_source = os.path.join(*split_path[1:])
    else:
        root_no_source = os.path.join(*split_path)

    basename = "{}.ks".format(os.path.splitext(basename)[0])

    # minified files must match directory structure of files in source, ensure
    # directories exist
    target_dir_rel = kwargs.get('override_target', './minified')
    dest_dir = os.path.join(target_dir_rel, root_no_source)
    dest_path = os.path.join(dest_dir, basename)
    os.makedirs(dest_dir, exist_ok=True)

    with open(file_path, 'r') as rf:
        file_lines = rf.readlines()

    file_oneline = compile_single_file_lines(file_lines, minifier_actions, **kwargs)

    with open(dest_path, 'w') as wf:
        wf.write(file_oneline)


def main_generate_parser():
    import argparse

    parser = argparse.ArgumentParser("ksx: KerboScript Extended transpiler")

    parser.add_argument(
        "--nuke",
        action='store_true',
        help="Clean out the 'minified' directory")
    parser.add_argument(
        "--transpile-only",
        action="store_true",
        help="Only perform transpilation from .ks to .ksx, no further optimizations")
    parser.add_argument(
        "--safe",
        action='store_true',
        help=("Perform just a safe subset of the minification routines, "
              "this will only use routines which have proven to be safe "
              "in actual operation."))
    parser.add_argument(
        "--single-file",
        help="Specify a single file to transpile")
    parser.add_argument(
        "--all-files",
        action='store_true',
        help="Transpile all .ks & .ksx files in the source directory")
    parser.add_argument(
        "--include", "-I",
        action="append",
        nargs="*",
        help="Extend include path for import mechanism",
    )

    return parser


TRANSPILER_ACTIONS = {
    "linewise": [
        [ksx_expand_import, ["transpile-only", "safe"]],
        [ksx_expand_from_import, ["transpile-only", "safe"]],
        [ksx_remove_lines, ["transpile-only", "safe"]],
        [min_strip_comments, ["safe"]],
        [min_remove_whitespace, []],
        [min_remove_blank_lines, ["safe"]],
    ],
    "oneline": [
        [min_remove_useless_space, []],
    ],
}


def main(args):
    # the internal lists also set execution order for rules
    if args.nuke:
        nuke_minified_directory()

    if args.single_file:
        files_to_compile = [args.single_file]
    elif args.all_files:
        files_to_compile = find_all_ks_files("./source/")
    else:
        files_to_compile = []

    for single_file in files_to_compile:
        compile_single_file(
            single_file,
            TRANSPILER_ACTIONS,
            transpile_only=args.transpile_only,
            safe_only=args.safe,
            include_paths=flatten(args.include or []),
        )

if __name__ == '__main__':
    main(main_generate_parser().parse_args())
