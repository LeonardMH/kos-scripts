# TODO: This should not be necessary, figure out how to get pytest to include
# the root path in it search path, rather than descending into tests/
import os; import sys; sys.path.append(os.path.abspath("."))
import pytest
import ksx


def assert_source_identity(source, **kwargs):
    """Check that `source` file is unchanged by the requested compile"""
    return assert_source_to_target(source, source, **kwargs)


def assert_source_to_target(source, target, **kwargs):
    """Check that `source` file is transformed into `target` file"""
    import filecmp
    import os

    ksx.compile_single_file(
        f'tests/assertfiles/{source}',
        ksx.TRANSPILER_ACTIONS,
        override_target='tests/genfiles',
        include_paths=kwargs.get('include_paths', ['tests/assertfiles']),
        **kwargs)

    a = f'tests/assertfiles/{target}'
    b = f'tests/genfiles/tests/assertfiles/{os.path.splitext(source)[0]}.ks'
    comparison = filecmp.cmp(a, b, shallow=False)

    if not kwargs.get('skip_assert', False):
        assert comparison

    return comparison


def test_gh_issue_3p0():
    """Surrounding spaces are removed from operators inside a string

    Attempting to print the following message:

    ```
    clearscreen. print "Takeoff routine complete, warping to AP...".
    ```

    Results in `Takeoff routine complete,warping to AP...` being printed.
    """
    assert_source_identity("gh_issue_3p0_source.ksx")


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
        "gh_issue_4p0_source.ksx",
        "gh_issue_4_target.ksx",
        transpile_only=True)


def test_gh_issue_4p1():
    """Same as above, but for @ksx from import statement"""
    assert_source_to_target(
        "gh_issue_4p1_source.ksx",
        "gh_issue_4_target.ksx",
        transpile_only=True)


def test_gh_issue_7p0():
    """Add recursive descent expansion of import statements

    Currently, if you import a file that imports another file, only the first
    file will be included, this is functionality breaking behavior and needs to
    be fixed ASAP. Every import and from x import y statement should be
    expanded recursively until there are no more statements to expand.

    I can easily see this leading to duplicate imports though, so that needs to
    be considered, it would be a shame if the 'minifier' tool ended up with
    exploding file sizes because of duplicate imports.
    """
    assert_source_to_target(
        "import_an_import.ksx",
        "gh_issue_7p0_target.ks",
        transpile_only=True)


@pytest.mark.skip(reason="Circular imports are still a known issue")
def test_gh_issue_7p1():
    """File 1 imports File 2, which in turn imports File 1"""
    assert_source_to_target(
        "reference_loop_1.ksx",
        "gh_issue_7p1_target.ks",
        transpile_only=True)


@pytest.mark.skip(reason="Circular imports are still a known issue")
def test_gh_issue_7p2():
    """File 2 imports File 1, which in turn imports File 2 (inverse of 7p1)"""
    assert_source_to_target(
        "reference_loop_2.ksx",
        "gh_issue_7p2_target.ks",
        transpile_only=True)
