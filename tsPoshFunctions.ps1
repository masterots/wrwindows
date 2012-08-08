function wrb {
    cd c:\svnwork\prr\branch\working\quality\webrunner
    mvn verify -P run-webrunner-nofork
}

function wrbClean {
    cd c:\svnwork\prr\branch
    
    echo "Compiling external schemas..."
    cd c:\svnwork\prr\branch\working\schema\external
    mvn -q clean install -DskipTests

    echo "Compiling prr code..."
    cd c:\svnwork\prr\branch\working\product
    mvn -q clean install -DskipTests

    echo "Compiling webrunner and support code..."
    cd c:\svnwork\prr\branch\working\quality
    mvn -q clean install -DskipTests

    echo "Compiling prr code..."
    cd c:\svnwork\prr\branch\working\quality\webrunner
    mvn verify -P run-webrunner-nofork
}