# Network-Monitor
Small ruby script to run ping for 60 seconds and evaluate the loss percentage and log results.

```shell
If the loss percentage is 0
  Log basic stats
  Sleep for 4 mins

If the loss percentage is less than 10 percent
  Log basic stats
  Immediately repeat ping monitoring

If the loss percentage greater than 10 percent
  Log all the output from ping
  Immediately repeat ping monitoring
```

### Usage
ruby network_monitor.rb

**As a detached process:**
ruby network_monitor.rb > /dev/null &


### Output

Written to file based on current date

Example output file: **2021-03-10.txt**
```yaml
SEQ:[1] {:transmitted=>60, :received=>60, :loss_pct=>0.0} finished at [2021-03-10T17:26:02-05:00] after 59 seconds
SEQ:[2] {:transmitted=>60, :received=>60, :loss_pct=>0.0} finished at [2021-03-10T17:31:01-05:00] after 59 seconds
SEQ:[3] {:transmitted=>60, :received=>60, :loss_pct=>0.0} finished at [2021-03-10T17:36:00-05:00] after 59 seconds
SEQ:[4] {:transmitted=>60, :received=>60, :loss_pct=>0.0} finished at [2021-03-10T17:40:59-05:00] after 59 seconds
```
