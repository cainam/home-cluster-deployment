#!/usr/bin/python

from ansible.errors import AnsibleError
import re
class FilterModule(object):
    def filters(self):
        return {
            'or_array': self.or_array
        }

    def or_array(self, bool_array):
        ##a_new_variable = a_variable + ' CRAZY NEW FILTER'
        if not isinstance(bool_array, list):
            raise AnsibleError('this function processes a list but %s provided' % str(type(bool_array)) )
        if not bool_array:
            raise AnsibleError('the list provided is not usable (length:%s)' % len(bool_array) )

        for item in bool_array:
            if not isinstance(item, bool):
                raise AnsibleError('this function processes a list of boolean, but at least one item of type %s was provided' % str(type(item)) )
                
        outval = None
        for item in bool_array:
            outval = outval or item
        return outval
