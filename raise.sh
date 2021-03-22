function create_rfc()
{
	echo "create rfc"
    AMS_RFC=$(aws amscm create-rfc --cli-input-json file://rfc_request.json --execution-parameters file://parameters.json --region us-east-1)
    
    echo "$AMS_RFC" > RFC_ID_Temp.json
    AMS_RFC_ID=$(jq -rc .RfcId RFC_ID_Temp.json)

    if [ ${#AMS_RFC_ID} -ge 20 ]; then
    echo "RFC created successfully"
      RFC_Status=$(aws amscm get-rfc --rfc-id $AMS_RFC_ID  --query 'Rfc.Status.Id' --output text --region us-east-1)
      if [ "$RFC_Status" = "Editing" ]; then
        echo "RFC is Ready for Submission"
        submit_rfc
      else
        echo "RFC is not ready for Submission, Exiting"
        exit 1
      fi
    fi

    if [ ${#AMS_RFC_ID} -le 20 ]; then
     echo "RFC creation failed, Exiting"
     exit 1
    fi
}

function submit_rfc()
{
	echo "submit rfc"
    RFC_Submit_Status=$(aws amscm submit-rfc --rfc-id $AMS_RFC_ID --output text --region us-east-1)
    query_rfc_status
}

function query_rfc_status()
{
	echo "query rfc status"

    for ((i = 0 ; i < 60 ; i++)); do
        RFC_Submit_Status=$(aws amscm get-rfc --rfc-id $AMS_RFC_ID --query 'Rfc.Status.Id' --output=text --region us-east-1)
        sleep 20
        
        if [ "$RFC_Submit_Status" = "InProgress" ] || [ "$RFC_Submit_Status" = "PendingApproval" ]; then
            echo "RFC status is $RFC_Submit_Status"
            continue
        elif [ "$RFC_Submit_Status" = "Success" ];then
            echo "RFC status is success"
            echo "RFC execution output:"
            aws amscm get-rfc --rfc-id $AMS_RFC_ID --query 'Rfc.ExecutionOutput' --output=text --region us-east-1
            exit 0
        else
            echo "RFC status is $RFC_Submit_Status. Pls investigate further, Exiting"
            echo "RFC execution output:"
            aws amscm get-rfc --rfc-id $AMS_RFC_ID --query 'Rfc.ExecutionOutput' --output=text --region us-east-1
            exit 1
        fi      
    done

    echo "RFC status is not 'Success' after 20 minutes, Exiting. Current status: $RFC_Submit_Status "
    echo "Current RFC status is $RFC_Submit_Status "
    echo "Pls investigate further"
    exit 1               
}

create_rfc
