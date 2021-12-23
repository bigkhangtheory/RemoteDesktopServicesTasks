# RdGatewayManagedComputerGroups

The **RdGatewayManagedComputerGroups** DSC configuration is used to create a local collection of remote computers for the RD Gateway server to manage RDP connections

<br />

## Project Information

|                  |                                                                                                                                                               |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Source**       | https://prod1gitlab.mapcom.local/dsc/configurations/ComputerManagementTasks/-/tree/master/ComputerManagementTasks/DscResources/RdGatewayManagedComputerGroups |
| **Dependencies** | [PSDesiredStateConfiguration][PSDesiredStateConfiguration]                                                                                                    |
| **Resources**    | [File][File], [Script][Script]                                                                                                                                |

<br />

## Parameters

<br />

### Table. Attributes of `RdGatewayManagedComputerGroups`

| Parameter          | Attribute  | DataType        | Description                                           | Allowed Values |
| :----------------- | :--------- | :-------------- | :---------------------------------------------------- | :------------- |
| **DomainDn**       | *Required* | `[String]`      | Distinguished Name (DN) of the domain.                |                |
| **ComputerGroups** |            | `[Hashtable[]]` | Specify a list of RD Gateway managed computer groups. |                |

---

#### Table. Attributes of `ComputerGroups`

| Parameter       | Attribute  | DataType   | Description                                                                                                                       | Allowed Values |
| :-------------- | :--------- | :--------- | :-------------------------------------------------------------------------------------------------------------------------------- | :------------- |
| **Name**        | *Required* | `[String]` | Specify a name for the RD RAP.                                                                                                    |                |
| **Description** |            | `[String]` | Specify a description to be included for the RD RAP.                                                                              |                |
| **Computers**   | *Required* | `[String]` | Specify a list of remote computers to add into the RD Gateway managed computer group. *Specify the NETBIOS name of the computer.* |                |

---

<br />

## Example *RdGatewayManagedComputerGroups*

```yaml
RdGatewayManagedComputerGroups:
  DomainDN: DC=mapcom,DC=local
  ComputerGroups:
  - Name: RDG_Group_RDCBComputers
    Description: All RDCB Computers in the deployment
    Computers:
      - DC1-RDCB-SRV01
      - DC2-RDCB-SRV01

  # ---
  - Name: RDG_Group_Workstations
    Description: This RD Gateway managed group collects domain workstations granted RDP availibility
    Computers:
      - CHEPC-MJ0X1234
      - CHEPC-MJ0Y1234
      - CHEPC-MJ0Z1234
```

<br />

## Lookup Options in `Datum.yml`

```yaml
lookup_options:

  RdGatewayManagedComputerGroups:
    merge_hash: deep
  RdGatewayManagedComputerGroups\ComputerGroups:
    merge_baseType_array: Unique
    merge_hash_array: UniqueKeyValTuples
    merge_options:
      tuple_keys:
        - Name

```

[File]: https://docs.microsoft.com/en-us/powershell/module/psdesiredstateconfiguration/?view=powershell-7.1
[Script]: https://docs.microsoft.com/en-us/powershell/module/psdesiredstateconfiguration/?view=powershell-7.1
[PSDesiredStateConfiguration]: https://docs.microsoft.com/en-us/powershell/module/psdesiredstateconfiguration/?view=powershell-7.1
