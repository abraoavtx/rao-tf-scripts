from tracemalloc import stop
import oci
import logging
import traceback
import sys

from pip import main

logging.basicConfig(format='%(asctime)s:%(levelname)s:%(message)s', level=logging.NOTSET)
logger = logging.getLogger()


class Oci_Utils:
    def __init__(self, region_name, config,
                 compartment_id="ocid1.compartment.oc1..aaaaaaaabspc6ozonnaaxw3puclufh27wmruskve5kzuuhryxh6za2hezn5q"):
        self.region_name = region_name
        # self.config = config
        self.compartmentid = compartment_id
        self.client = oci.core.ComputeClient(config)
       
    def list_instance(self, lifecycle_state):
        self.result = []
        self.client.base_client.set_region(self.region_name)
        logger.info("Setting  the region to %s" % self.region_name)
        try:
            instance_list = self.client.list_instances(self.compartmentid, lifecycle_state=lifecycle_state)
            logger.info("Fetching all the instances in the compartmenet %s" % self.compartmentid)
            for i in instance_list.data:
                self.result.append(i.display_name)
        except Exception as e:
            traceback_msg = traceback.format_exc()
            logging.error(traceback_msg)
        #print(instance_list.data)
        print(self.result)
        return instance_list.data
    
    def stop_instances(self):
        vm_data = self.list_instance("RUNNING")
        stopped_vms = []
        for each_instance in vm_data:
            #logger.info(dir(self.client))
            if each_instance.display_name.endswith("vm"):
                logger.info(each_instance.display_name)
                stopped_vms.append(each_instance.display_name)
                self.client.instance_action(each_instance.id,"SOFTSTOP")
                #self.client.instance_action(each_instance.id,"START")
            logger.info("STOPPED ALL THE INSTANCES {}".format(stopped_vms))
            logger.info("Instances {} is stopped with action {}".format(stopped_vms , "STOP"))
        return stopped_vms

    
    def start_instances(self):
        vm_data = self.list_instance("STOPPED")
        started_vms = []
        for each_instance in vm_data:
            #self.client.instance_action(each_instance.id,"SOFTSTOP")
            #logger.info(dir(self.client))
            started_vms.append(each_instance.display_name)
            if each_instance.display_name.endswith("vm"):
                self.client.instance_action(each_instance.id,"START")
                logger.info("STARTED ALL THE INSTANCES {}".format(started_vms))
            logger.info("Instance {} is started with action {}".format(started_vms , each_instance.lifecycle_state))
        return started_vms
    
    def terminate_instances(self):
        vm_data = self.list_instance("STOPPED") or self.list_instance("RUNNING") 
        terminated_vms = []
        for each_instance in vm_data:
            #self.client.instance_action(each_instance.id,"SOFTSTOP")
            #logger.info(dir(self.client))
            terminated_vms.append(each_instance.display_name)
            if each_instance.display_name.endswith("vm"):
                self.client.terminate_instance(each_instance.id)
                logger.info("Terminated All the instances {}".format(terminated_vms))
            logger.info("Instance {} are  terminated".format(terminated_vms))
        return terminated_vms


def main():
    config = oci.config.from_file(file_location='~/.oci-new/config_file')
    output = Oci_Utils("us-phoenix-1", config=config)
    if len(sys.argv) < 2:
        print("Usage: python start_stop.py {start|stop|terminate}\n")
        sys.exit(0)
    else:
        action = sys.argv[1] 
        if action == "start":
            output.start_instances()
        elif action == "stop":
            output.stop_instances()
        elif action == 'terminate':
            output.terminate_instances()
        else:
            print("Usage: python aws.py {start|stop|terminate}\n")

main()
