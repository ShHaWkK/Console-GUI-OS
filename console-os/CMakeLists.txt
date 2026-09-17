cmake_minimum_required(VERSION 3.24)

project(ConsoleOS LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick DBus Test)
find_package(Python3 COMPONENTS Interpreter)

add_library(console-core
    core/manifest.cpp
)
target_include_directories(console-core PUBLIC core)
target_link_libraries(console-core PUBLIC Qt6::Core)

add_executable(game-manager
    services/game-manager/main.cpp
    services/game-manager/manager.cpp
)
target_include_directories(game-manager PRIVATE services/game-manager)
target_link_libraries(game-manager PRIVATE console-core Qt6::Core Qt6::DBus)

add_executable(console-shell
    shell/main.cpp
    shell/backend.cpp
    shell/shell.qrc
)
target_include_directories(console-shell PRIVATE shell)
target_link_libraries(console-shell PRIVATE console-core Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::DBus)

add_executable(hello-console
    examples/hello-console/main.cpp
    examples/hello-console/hello-console.qrc
)
target_link_libraries(hello-console PRIVATE console-core Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick)

add_executable(test-manifest
    tests/test_manifest.cpp
)
target_link_libraries(test-manifest PRIVATE console-core Qt6::Test)

add_executable(test-manager
    tests/test_manager.cpp
    services/game-manager/manager.cpp
)
target_include_directories(test-manager PRIVATE services/game-manager)
target_link_libraries(test-manager PRIVATE console-core Qt6::Test)

add_executable(ipc-client
    tests/ipc_client.cpp
)
target_link_libraries(ipc-client PRIVATE Qt6::Core Qt6::DBus)

add_custom_command(TARGET hello-console POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/catalog/org.consoleos.hello"
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:hello-console>" "${CMAKE_BINARY_DIR}/catalog/org.consoleos.hello/hello-console"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/examples/hello-console/game.json"
            "${CMAKE_BINARY_DIR}/catalog/org.consoleos.hello/game.json"
    COMMENT "Preparing local Hello Console catalog entry"
)

enable_testing()
add_test(NAME manifest COMMAND test-manifest)
add_test(NAME manager COMMAND test-manager)

if(Python3_Interpreter_FOUND)
    add_test(NAME integration
        COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/integration.py" "$<TARGET_FILE:game-manager>"
    )
    set_tests_properties(integration PROPERTIES
        SKIP_REGULAR_EXPRESSION "^SKIP:"
    )

    # Optionnel : ignoré (SKIP) si PySide6 n'est pas installé, plutôt que de
    # rendre la dépendance obligatoire pour tout le monde (voir docs/build.md).
    # Rendu hors-écran pour fonctionner sans serveur graphique (CI, WSL...).
    add_test(NAME qml-smoke
        COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/qml_smoke.py"
    )
    set_tests_properties(qml-smoke PROPERTIES
        SKIP_REGULAR_EXPRESSION "^SKIP:"
        ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software"
    )
endif()

install(TARGETS console-shell game-manager RUNTIME DESTINATION bin)
install(TARGETS hello-console RUNTIME DESTINATION share/console-os/games/org.consoleos.hello)
install(FILES examples/hello-console/game.json DESTINATION share/console-os/games/org.consoleos.hello)
install(PROGRAMS
    system/scripts/console-session
    system/scripts/console-graphical-session
    system/scripts/dev.sh
    system/scripts/run-dev.sh
    DESTINATION share/console-os/scripts
)
install(DIRECTORY docs DESTINATION share/doc/console-os)
install(DIRECTORY system/config DESTINATION share/console-os)
