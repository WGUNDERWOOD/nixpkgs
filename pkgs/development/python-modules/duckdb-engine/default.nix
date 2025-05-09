{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pytestCheckHook,
  pythonAtLeast,
  pythonOlder,
  python,
  duckdb,
  hypothesis,
  pandas,
  pyarrow,
  poetry-core,
  pytest-remotedata,
  snapshottest,
  sqlalchemy,
  typing-extensions,
}:

buildPythonPackage rec {
  pname = "duckdb-engine";
  version = "0.15.0";
  pyproject = true;

  disabled = pythonOlder "3.8";

  src = fetchFromGitHub {
    repo = "duckdb_engine";
    owner = "Mause";
    tag = "v${version}";
    hash = "sha256-mxv6xYO31MDzHvIf7Zk+kFtm6fX3x3AaJNn7RhvJ2fY=";
  };

  nativeBuildInputs = [ poetry-core ];

  propagatedBuildInputs = [
    duckdb
    sqlalchemy
  ];

  preCheck = ''
    export HOME="$(mktemp -d)"
  '';

  nativeCheckInputs = [ pytestCheckHook ];

  checkInputs =
    [
      hypothesis
      pandas
      pytest-remotedata
      typing-extensions
      pyarrow
    ]
    ++ lib.optionals (pythonOlder "3.12") [
      # requires wasmer which is broken for python 3.12
      # https://github.com/wasmerio/wasmer-python/issues/778
      snapshottest
    ];

  pytestFlagsArray = [
    "-m"
    "'not remote_data'"
  ];

  disabledTestPaths = lib.optionals (pythonAtLeast "3.12") [
    # requires snapshottest
    "duckdb_engine/tests/test_datatypes.py"
  ];

  disabledTests =
    [
      # incompatible with duckdb 1.1.1
      "test_with_cache"
      # these aren't set for some reason
      "test_user_agent"
      "test_user_agent_with_custom_user_agent"
    ]
    ++ lib.optionals (python.pythonVersion == "3.11") [
      # incompatible with duckdb 1.1.1
      "test_all_types_reflection"
      "test_nested_types"
    ];

  pythonImportsCheck = [ "duckdb_engine" ];

  meta = with lib; {
    description = "SQLAlchemy driver for duckdb";
    homepage = "https://github.com/Mause/duckdb_engine";
    changelog = "https://github.com/Mause/duckdb_engine/blob/${src.tag}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = with maintainers; [ cpcloud ];
  };
}
