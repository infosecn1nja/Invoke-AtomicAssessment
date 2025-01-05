# Invoke-AtomicAssessment
<img width="638" alt="image" src="images/flow.png">

Invoke-AtomicAssessment is a powerful tool designed to facilitate adversary emulation by leveraging Atomic Red Team. This tool automates the execution of these techniques and logs the results in the ATTiRe format, which can then be visualized on the VECTR platform. The tool offers various threat actor profiles, enabling simulations of ransomware attacks and activities of Advanced Persistent Threat (APT) groups. The primary goal is to conduct thorough gap analysis to identify and remediate weaknesses in security defenses.

## Profiles
The tool includes a collection of pre-configured threat actor profiles, which can be used to simulate specific adversaries or attack scenarios. Below is a list of available profiles:
- Akira: A ransomware group known for targeting enterprises.
- APT41: A Chinese state-sponsored threat group involved in cyber espionage and financial gain.
- BlackCat (ALPHV): A ransomware-as-a-service (RaaS) group targeting multiple industries.
- Lazarus: A North Korean APT group linked to cyber espionage and destructive attacks.
- LockBit: A prolific ransomware group known for its fast encryption and double extortion tactics.
- Mustang Panda: A Chinese APT group focused on espionage and data exfiltration.
- OilRig: An Iranian threat group targeting Middle Eastern organizations for espionage.

In addition to the pre-configured profiles, Invoke-AtomicAssessment allows users to create custom profiles tailored to specific threat actors or attack scenarios. Custom profiles follow a structured JSON format, as shown below:
```
{
  "name": "APT41",
  "description": "APT41 is a threat group that researchers have assessed as Chinese state-sponsored espionage group that also conducts financially-motivated operations. Active since at least 2012, APT41 has been observed targeting healthcare, telecom, technology, and video game industries in 14 countries. APT41 overlaps at least partially with public reporting on groups including BARIUM and Winnti Group.",
  "references": [
    "https://www.group-ib.com/blog/apt41-world-tour-2021/",
    "https://cloud.google.com/blog/topics/threat-intelligence/apt41-arisen-from-dust",
    "https://malpedia.caad.fkie.fraunhofer.de/actor/apt41"
  ],
  "operating_system": "windows",
  "AtomicTests": [
    {
      "TestNumber": 1,
      "Description": "Compiled HTML Help Local Payload",
      "Command": "Invoke-AtomicTest T1218.001 -TestNumber 1"
    },
    {
      "TestNumber": 2,
      "Description": "Rundll32 with Ordinal Value",
      "Command": "Invoke-AtomicTest T1218.011 -TestNumber 11"
    },
     {
      "TestNumber": 3,
      "Description": "DLL Side-Loading using the Notepad++ GUP.exe binary",
      "Commands": [
        "Invoke-AtomicTest T1574.002 -TestNumber 1 -GetPrereqs",
        "Invoke-AtomicTest T1574.002 -TestNumber 1"
      ]
    }   
  ]
}
```
Key Fields in Custom Profiles:
- name: The name of the threat actor or scenario.
- description: A detailed description of the threat actor, their tactics, and objectives.
- references: A list of URLs or sources providing additional information about the threat actor.
- operating_system: The target operating system for the tests.
- AtomicTests: A list of Atomic Red Team tests to execute, including:
  - TestNumber: The test number within the specific Atomic technique.
  - Description: A brief description of the test.
  - Command or Commands:
     - Command: A single command to execute the test using Invoke-AtomicTest.
     - Commands: A list of commands to execute for the test (useful for multi-step tests).

## Steps to Run Invoke-AtomicAssessment

### 1. Import the Module

Start by importing the `Invoke-AtomicAssessment` module into your PowerShell session. Ensure that the module's path is correctly specified.

```powershell
Import-Module .\Invoke-AtomicAssessment.ps1
```
### 2. Execute an Assessment
Use the Invoke-AtomicAssessment command to perform the adversary emulation. Replace `<group name>` with the name of the adversary group or profile you wish to simulate.
```
Invoke-AtomicAssessment -Adversary <group name>
```

### Example
In this example, the tool is set to simulate the behavior of the Lockbit ransomware, running their techniques against your environment to identify potential security gaps.
```
Import-Module .\Invoke-AtomicAssessment.ps1
Invoke-AtomicAssessment -Adversary Lockbit
```
After running Invoke-AtomicAssessment, the tool generates a single result file in the output folder.

### Steps to Import Logs in VECTR Platform

1. **Select Environment**  
   Navigate to the desired environment where the assessment will be conducted.

2. **Choose an Existing Assessment or Create a New One**  
   - Select an existing assessment from the list.  
   - Alternatively, click on **Start New Assessment** to create a new one.

3. **Import Logs via Assessment Actions**  
   - In the selected assessment, click the **Assessment Actions** dropdown menu.  
   - Choose **Import Logs** from the list.

4. **Upload Result File and Submit**  
   - Drag and drop the result file into the upload area or browse for it manually.  
   - Click the **Submit** button to upload.

5. **Select Test Cases and Confirm**  
   - After the log file is processed, a list of test cases will be displayed.  
   - Click **Select All Test Cases** to ensure all relevant data is included.  
   - Finally, click **Submit** to finalize the log import. 

These steps will successfully import the log file into the VECTR platform for analysis.

## License
This project is licensed under the GNU General Public License. For more details, please refer to the LICENSE file.

## Acknowledgements
* [Atomic Red Team](https://github.com/redcanaryco/atomic-red-team)
* [VECTR](https://github.com/SecurityRiskAdvisors/VECTR)