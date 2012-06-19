function cluster {
    ## Gives the cluster of the given client, or the cluster of the client whose folder you're in
    ## Author: lgoolsbee
    
    if ($args.count -gt 0)
	{
        CLIENTNAME=$(echo $1 | sed 's/\///g')
	}
    else {
        if ($(pwd) = "/svnwork/customers")
		{
            CLIENTNAME=$(basename `pwd`)
		}
   }
    
    if [ -d /svnwork/customers/trunk/working/$CLIENTNAME ]; then
        CL_WK="working"
    else
        CL_WK="clean"
    fi
    
    if [ -d /svnwork/customers/trunk/$CL_WK/$CLIENTNAME ]; then
        if [ -a /svnwork/customers/trunk/$CL_WK/$CLIENTNAME/settings/$CLIENTNAME.sh ]; then
            CLUSTERNUM=$(grep CUSTOMER_CLUSTER /svnwork/customers/trunk/$CL_WK/$CLIENTNAME/settings/$CLIENTNAME.sh | cut -d"=" -f 2 | sed 's/[[:punct:]]//g')
        else
            SETTINGSFILE=$(echo /svnwork/customers/trunk/$CL_WK/$CLIENTNAME/settings/*.sh)
            if [ -a $SETTINGSFILE ]; then
                CLUSTERNUM=$(grep CUSTOMER_CLUSTER $SETTINGSFILE | cut -d"=" -f 2 | sed 's/[[:punct:]]//g')
            fi
        fi
    fi
        
    if [ $# -gt 0 ]; then
        if [ $CLUSTERNUM ]; then
            echo $CLIENTNAME cluster: $CLUSTERNUM
        fi
    else
        if [ $CLUSTERNUM ]; then
            echo "($CLUSTERNUM)"
        fi
    fi
    
    unset CLIENTNAME CLUSTERNUM

}