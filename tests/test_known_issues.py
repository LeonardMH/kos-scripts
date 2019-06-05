# TODO: This should not be necessary, figure out how to get pytest to include
# the root path in it search path, rather than descending into tests/
import os; import sys; sys.path.append(os.path.abspath("."))
import ksx


def assert_source_to_target(source, target, **kwargs):
    import filecmp
    import os

    ksx.compile_single_file(
        f'tests/assertfiles/{source}',
        ksx.TRANSPILER_ACTIONS,
        override_target='tests/genfiles',
        include_paths=kwargs.get('include_paths', ['tests/assertfiles']),
        **kwargs)

    assert filecmp.cmp(
        f'tests/assertfiles/{target}',
        f'tests/genfiles/tests/assertfiles/{os.path.splitext(source)[0]}.ks',
        shallow=False)


def test_gh_issue_4p0():
    """@ksx directives are always inserted at the top of the file

    Directives such as:

    ```
    @ksx import ("lib/telemetry").
    ```

    Should be compiled so that the line is removed and replaced with the relevant
    file or function contents inside. This works, but always places the inlined
    text at the top of the compiled file.
    """
    assert_source_to_target(
        "gh_issue_4_source.ksx",
        "gh_issue_4_target.ksx",
        transpile_only=True)

def test_gh_issue_4p1():
    """Same as above, but for @ksx from import statement"""
    assert_source_to_target(
        "gh_issue_4p1_source.ksx",
        "gh_issue_4_target.ksx",
        transpile_only=True)
