# RdGatewayResourceAuthorizationPolicies

The **RdGatewayResourceAuthorizationPolicies** DSC configuration manages RD Gateway resource authorization policy (RD RAP) to allow users to connect to remote computers on the network by using RD Gateway.

RD RAPs allow you to specify the internal network resources that remote users can connect to through an RD Gateway server. When you create an RD RAP, you can create a computer group (a list of computers on the internal network to which you want the remote users to connect) and associate it with the RD RAP.

Remote users connecting to an internal network through an RD Gateway server are granted access to computers on the network if they meet the conditions specified in at least one RD CAP and one RD RAP.

<br />

## Project Information

|                  |                                                                                                                                                                       |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Source**       | https://prod1gitlab.mapcom.local/dsc/configurations/ComputerManagementTasks/-/tree/master/ComputerManagementTasks/DscResources/RdGatewayResourceAuthorizationPolicies |
| **Dependencies** | [PSDesiredStateConfiguration][PSDesiredStateConfiguration]                                                                                                            |
| **Resources**    | [File][File], [Script][Script]                                                                                                                                        |

<br />

## Parameters

<br />

### Table. Attributes of `RdGatewayResourceAuthorizationPolicies`

| Parameter    | Attribute  | DataType        | Description                                                              | Allowed Values |
| :----------- | :--------- | :-------------- | :----------------------------------------------------------------------- | :------------- |
| **DomainDn** | *Required* | `[String]`      | Distinguished Name (DN) of the domain.                                   |                |
| **Policies** |            | `[Hashtable[]]` | Specify a list of RD Gateway connection authorization policies (RD RAP). |                |

---

#### Table. Attributes of `Policies`

| Parameter             | Attribute  | DataType     | Description                                                                                                               | Allowed Values                                       |
| :-------------------- | :--------- | :----------- | :------------------------------------------------------------------------------------------------------------------------ | :--------------------------------------------------- |
| **Name**              | *Required* | `[String]`   | Specify a name for the RD RAP.                                                                                            |                                                      |
| **Status**            |            | `[String]`   | Specify whether the RD RAP should be enabled or disabled.                                                                 | `Enabled` *(Default)*, `Disabled`                    |
| **Description**       |            | `[String]`   | Specify a description to be included for the RD RAP.                                                                      |                                                      |
| **Ports**             |            | `[String[]]` | Specifies the type of ports that Remote Desktop Services clients can use when connecting to computers through RD Gateway. | `RDP` *(Default)*, `Any`                             |
| **ComputerGroupType** |            | `[String]`   | For more information see [Types of RD Gateway Network Resources](#####types-of-rd-gateway-network-resources).             | `GatewayManaged` *(Default)*, `DomainManaged`, `Any` |
| **ComputerGroup**     |            | `[String]`   | Specify the name of either the RD Gateway Managed Group or the AD Security Group.                                         |                                                      |
| **UserGroups**        | *Required* | `[String[]]` | Specify a list of security groups containing Users that are authorized to connect to the specified Computer groups.       |                                                      |

---

##### Types of RD Gateway Network Resources

Remote users can connect through RD Gateway to internal network resources in a security group or an RD Gateway-managed computer group. The group can be any one of the following:

- **GatewayManaged**. Select an existing RD Gateway-managed group or create a new one. You can configure an RD Gateway-managed computer group or select an existing one, by using Remote Desktop Gateway Manager after installation or the **RdGatewayManagedComputerGroup** DSC configuration.

- **DomainManaged**. The network resource group already exists in Active Directory Domain Services.

- **Any**. Allow users to connect to any network resource. In this case, users can connect to any computer on the internal network that they could connect to when they use Remote Desktop Connection.

> **Note**: An *RD Gateway-managed computer group* will not appear in Local Users and Groups on the RD Gateway server, nor can it be configured by using Local Users and Groups.
{.is-info}

<br />

## Example *RdGatewayResourceAuthorizationPolicies*

```yaml
RdGatewayResourceAuthorizationPolicies:
  DomainDN: DC=mapcom,DC=local
  Policies:
  - Name: RDG_RAP_HighAvailabilityBroker_DNS_RR
    Status: Enabled
    Description: DNS RR value
    Ports: RDP
    ComputerGroupType: GatewayManaged # ComputerGroupType = 0
    ComputerGroup: RDG_Group_DNSRoundRobin
    UserGroups:
      - Domain Users

  # ---

  - Name: RDG_RAP_WsusServers
    Status: Enabled
    Description: Authorized connections to WSUS servers
    Ports: Any
    ComputerGroupType: DomainManaged # ComputerGrouptype = 1
    ComputerGroup: WSUS Servers
    UserGroups:
      - System Administrators (IV)

  # ---

  - Name: RDG_RAP_AllDomainComputers
    Status: Enabled
    Description: All domain computers
    Ports: RDP
    ComputerGroupType: Any # ComputerGroupType = 2
    UserGroups:
      - Domain Users
```

<br />

## Lookup Options in `Datum.yml`

```yaml
lookup_options:

  RdGatewayResourceAuthorizationPolicies:
    merge_hash: deep
  RdGatewayResourceAuthorizationPolicies\Policies:
    merge_baseType_array: Unique
    merge_hash_array: UniqueKeyValTuples
    merge_options:
      tuple_keys:
        - Name

```

[File]: https://docs.microsoft.com/en-us/powershell/module/psdesiredstateconfiguration/?view=powershell-7.1
[Script]: https://docs.microsoft.com/en-us/powershell/module/psdesiredstateconfiguration/?view=powershell-7.1
[PSDesiredStateConfiguration]: https://docs.microsoft.com/en-us/powershell/module/psdesiredstateconfiguration/?view=powershell-7.1
