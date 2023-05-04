#Component/Product url
$component_file = Invoke-RestMethod -Uri "" #Github Raw Json URL for Component file

#pipeline
$token ="" #PAT-Token for ADO Pipeline
$organization_name=""  #provide  your organization of ADO
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$token)))
$pipeline_json = Invoke-RestMethod -Uri "" #Github Raw Json URL for Pipeline resource type and ID
$pipeline_resourceType = $pipeline_json.resources.resourceType
$depends_On_global="false"
$count=0
$test = $component_file.resources

foreach ($number in $test) {
    $name_of_resource = $component_file.resources[$count].name
    $type_of_resource = $component_file.resources[$count].properties.resourceType
    $depends_On_in_file = $component_file.resources[$count].properties.dependsOn

    #Matching condition of non-dependent resources
    if ( $depends_On_in_file -eq $depends_On_global ) {

        #Matching condition of resource type with the pipeline resources list
        if ($pipeline_resourceType -eq $type_of_resource) {
            Write-Host $type_of_resource

        # To fetch the ID url
        $fetchPipelineId = Invoke-RestMethod -Uri "" ` #Github Raw Json URL for Pipeline ID
      | Select-Object -ExpandProperty "resources" `
      | Where-Object { $_.resourceType -eq $type_of_resource } `
      | Group-Object -Property "pipelineID" `
      | Select-Object -Property Name  | Out-String -NoNewline

            $pipelineId = $fetchPipelineId.TrimStart("Name----")
            Write-Host "Type of resource:- $type_of_resource Pipeline ID of resource:-" $pipelineId

            $url = "https://dev.azure.com/$organization_name/$type_of_resource/_apis/pipelines/$pipelineId/runs?api-version=7.0-preview"

            $body = @{
                resources = @{
                    repositories = @{
                        self = @{
                            refName ="refs/heads/$type_of_resource"
                        }
                    }
                }
            } | ConvertTo-Json

            $response = Invoke-RestMethod -Method Post -Uri $url -Headers @{Authorization = "Basic $base64AuthInfo" } -ContentType "application/json" -Body $body
        }

    }
    $count++
}