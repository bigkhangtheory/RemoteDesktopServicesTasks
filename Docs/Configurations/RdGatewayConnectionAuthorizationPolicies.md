# RdGatewayConnectionAuthorizationPolicies

The **RdGatewayConnectionAuthorizationPolicies** DSC configuration is used to manage Remote Desktop connection authorization policies (RD CAP) to allow users access to a RD Gateway server.

RD CAPs allow you to specify who can connect to an RD Gateway server. You can specify a user group that exists on the local RD Gateway server or in Active Directory Domain Services. You can also specify other conditions that users must meet to access an RD Gateway server. You can list specific conditions in each RD CAP. For example, you might require a group of users to use a smart card to connect through RD Gateway.

> Users are granted access to an RD Gateway server if they meet the conditions specified in the RD CAP. You must also create a Remote Desktop resource authorization policy (RD RAP). An RD RAP allows you to specify the network resources (computers) that users can connect to through RD Gateway. Until you create both an RD CAP and an RD RAP, users cannot connect to network resources through this RD Gateway server.
{.is-danger}

<br />

## Project Information

|                  |                                                                                                                                                                         |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Source**       | https://prod1gitlab.mapcom.local/dsc/configurations/ComputerManagementTasks/-/tree/master/ComputerManagementTasks/DscResources/RdGatewayConnectionAuthorizationPolicies |
| **Dependencies** | [PSDesiredStateConfiguration][PSDesiredStateConfiguration]                                                                                                              |
| **Resources**    | [File][File], [Script][Script]                                                                                                                                          |

<br />

## Parameters

<br />

### Table. Attributes of `RdGatewayConnectionAuthorizationPolicies`

| Parameter    | Attribute  | DataType        | Description                                                              | Allowed Values |
| :----------- | :--------- | :-------------- | :----------------------------------------------------------------------- | :------------- |
| **DomainDn** | *Required* | `[String]`      | Distinguished Name (DN) of the domain.                                   |                |
| **Policies** |            | `[Hashtable[]]` | Specify a list of RD Gateway connection authorization policies (RD CAP). |                |


---

#### Table. Attributes of `Policies`

| Parameter                | Attribute  | DataType     | Description                                                                                                    | Allowed Values                                      |
| :----------------------- | :--------- | :----------- | :------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------- |
| **Name**                 | *Required* | `[String]`   | Specify a name for the RD CAP.                                                                                 |                                                     |
| **UserGroups**           | *Required* | `[String[]]` | Specify a list of security groups containing Users.                                                            |                                                     |
| **Status**               |            | `[String]`   | Specify whether the RD CAP should be enabled or disabled.                                                      | `Enabled` *(Default)*, `Disabled`                   |
| **AuthMethod**           |            | `[String]`   | Specify the authentication methods that the RD Gateway server will allow from the user group.                  | `Password` *(Default)*, `SmartCard`, `None`, `Both` |
| **IdleTimeout**          |            | `[UInt32]`   | Sets the maximum time, in minutes, that a remote session can be *idle* before the session is disconnected.     | `0` *(Default)* - `1440`                            |
| **SessionTimeout**       |            | `[UInt32]`   | Sets session timeout settings, in minutes, for a remote session when connecting through the RD Gateway server. | `0` *(Default)* - `32766`                           |
| **SessionTimeoutAction** |            | `[String]`   | Specifies the action to take after the user session timeout is reached.                                        | `Disconnect` *(Default)*, `Reauthorize`             |

> **Note**: The attribute `Policies` is an ordered list. The ordering of the hashtable entries have a direct relationship with the evaluation order of the RD CAP on a RD Gateway server.
{.is-info}

---

<br />

## Example *RdGatewayConnectionAuthorizationPolicies*

```yaml
RdGatewayConnectionAuthorizationPolicies:
  DomainDN: DC=mapcom,DC=local
  Policies:
    - Name: RDG_CAP_DomainUsers
      UserGroups:
        - Domain Users
      Status: Enabled
      AuthMethod: Password
      IdleTimeOut: 1440
      SessionTimeout: 0
      SessionTimeoutAction: Disconnect

# ---

    - Name: RDG_CAP_Evaluation
      UserGroups:
        - System Administrators (I)
        - System Administrators (II)
        - System Administrators (III)
      Status: Enabled
      AuthMethod: Password
      IdleTimeOut: 1440
      SessionTimeout: 0
      SessionTimeoutAction: Disconnect
```

<br />

## Lookup Options in `Datum.yml`

```yaml
lookup_options:

  RdGatewayConnectionAuthorizationPolicies:
    merge_hash: deep
  RdGatewayConnectionAuthorizationPolicies\Policies:
    merge_baseType_array: Unique
    merge_hash_array: UniqueKeyValTuples
    merge_options:
      tuple_keys:
        - Name

```

[File]: https://docs.microsoft.com/en-us/powershell/module/psdesiredstateconfiguration/?view=powershell-7.1
[Script]: https://docs.microsoft.com/en-us/powershell/module/psdesiredstateconfiguration/?view=powershell-7.1
[PSDesiredStateConfiguration]: https://docs.microsoft.com/en-us/powershell/module/psdesiredstateconfiguration/?view=powershell-7.1
