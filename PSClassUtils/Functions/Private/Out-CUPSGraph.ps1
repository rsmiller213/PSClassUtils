Function Out-CUPSGraph {
    <#
    .SYNOPSIS
        Generates the graph output. It requires input from Get-CUAST (input of type ASTDOcument)
    .DESCRIPTION
        This function is based on psgraph, which wih is a module to generate diagrams using GraphViz. If psgraph is not present, it will throw.
    .EXAMPLE
        
        
    .INPUTS
        Pipeline input from a ASTDocument Object
    .OUTPUTS
        Output (if any)


    .PARAMETER InputObject
    This parameter expects an array of ASTDocument. (Can be generated using Get-CUAST).


    .PARAMETER IgnoreCase

    If there is a difference in the casesensitivity of the a parent class, and it's child class, drawing the inheritence might not work as expected.
    Forcing the case sensitivy to be everywhere the same when creating the objects in PSGraph resolves this issue (See issue here -> https://github.com/KevinMarquette/PSGraph/issues/68 )
    Using -IgnoreCase will force all class names to be set to 'TitleCase', reglardless of the case sensitivity they had before.

    .NOTES
        General notes
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ValueFromPipeline = $true)]
        [Object[]]$inputObject,


        [Parameter(Mandatory = $False)]
        [Switch]
        $IgnoreCase


    )
    
    begin {
        $AllGraphs = @()
        if(!(Get-Module -Name PSGraph)){
            #Module is not loaded
            if(!(get-module -listavailable -name psgraph )){
                #Module is not present
                throw "The module PSGraph is a prerequisite for this function to work. Please Install PSGraph first (You can use Install-CUDiagramPrerequisites to install them.)"
            }else{
                Import-Module psgraph -Force
            }
        }
    }
    
    process {

        $Graph = Graph {
            foreach($obj in $inputObject){
                $CurrName = split-Path -leaf $obj.Name
                subgraph -Attributes @{label=($CurrName)} -ScriptBlock {
                        Foreach( $Class in $obj.Group ) {
        
                            $RecordName = $Class.Name
                            $Constructors = $Class.Constructor
                            $Methods = $Class.Method
                            $Properties = $Class.Property
        
                            Record -Name $RecordName {
                                If ($Properties) {
        
                                    Foreach ($pro in $Properties) {
        
                                        if ($pro.Visibility -eq "Hidden") {
                                            $visibility = "-"
                                        } Else {
                                            $visibility = "+"
                                        }
                                        
                                        $n = "$($visibility) [$($pro.Type)] `$$($pro.Name)"
                                        if ($n) {
                                            Row -label "$($n)"  -Name "Row_$($pro.Name)"
                                        }
                                        else {
                                            $pro.name
                                        }
                    
                                    }
        
                                }
        
                                Row "-----Constructors-----"  -Name "Row_Separator_Constructors"
                                #Constructors
                                If ( $Constructors ) {
                                    foreach ($con in $Constructors) {
                                        
                                        $RowName = "$($con.Name)"
                                        
                                        If ( $con.Parameter ) {
                                            foreach ($c in $con.Parameter) {
                                                $Parstr = $Parstr + $C.Type + '$' + $c.Name + ","
                                            }
                                            
                                            $Parstr = $Parstr.trim(",")
                                        }
        
                                        If ($Parstr) {
                                            $RowName = $RowName + "(" + $Parstr + ")"
                                        } Else {
                                            $RowName = $RowName + "()"
                                        }
            
                                        Row $RowName -Name "Row_$($con.Name)"
                                        
                                    }
                                } Else {
                                    
                                }
                                
                                #Methods Raw
                                Row "-----Methods-----"  -Name "Row_Separator_Methods"
                                
                                If ( $Methods ) {
                                    #Write-Host $Methods.Count
                                    #$i=0
                                    Foreach ($mem in $Methods) {
        
                                        $visibility = "+"
                                        $Parstr = ""
        
                                        If ( $mem.Parameter ) {
                                            ForEach ( $p in $mem.Parameter ) {
                                                $Parstr = $Parstr +  $p.Type + '$' + $p.Name + ","
                                            }
                                        
                                            $Parstr = $Parstr.trim(",")
                                        }
                                        
                                        $RowName = "$($mem.Name)"
                                        
        
                                        If ( $Parstr ) {
                                            $RowName = $RowName + "(" + $Parstr + ")"
                                        } Else {
                                            $RowName = $RowName + "()"
                                        }
                
                                        If ( $mem.IsHidden ) {
                                            $visibility = "-"
                                        }
        
                                        $RowName = $visibility + $RowName
                                        #$i++
                                        #write-host $i + ' - ' + $RowName
                                        Row $RowName -Name "Row_$($mem.Name)"
                                    }
                                }
                        
                            }#End Record
                        }#end foreach Class
        
                    }#End SubGraph
                
                ## InHeritance
                Foreach ($class in ($Obj.Group | where-Object IsInherited)){
                    $Parent = $Class.ParentClassName
                    $Child = $Class.Name
                    edge -From $Parent -To $Child
                }
            }
        }

        $AlLGraphs += $Graph
    }
    
    end {

        Return $AlLGraphs
    
    }
}