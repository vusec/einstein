from django.db import models
from db_manage import init_django
import yaml
from django.forms.models import model_to_dict
from django.contrib.postgres.fields import ArrayField

class Limits():
    MATCH_LEN_MAX = 16          # NOTE: If this is changed, then also change EVAL_MATCH_LEN_MAX in einstein_rewrite.cpp
    MATCH_LEN_MIN = 1
    MATCH_LEN_DEFAULT = 1
    MATCH_LEN_GET_IFLOWS = 4    # For the get_iflows eval: Let's only target iflows with a match_len >= MATCH_LEN_GET_IFLOWS. NOTE: If this is changed, then also change EVAL_MATCH_LEN in einstein_rewrite.cpp.
    PTR_DEPTH_LIMIT_MAX = 10
    PTR_DEPTH_LIMIT_MIN = 0
    PTR_DEPTH_LIMIT_DEFAULT = 3
    TAGS_PER_TAGSET_MAX = 16
    TAGS_PER_TAGSET_MIN = 1
    TAGS_PER_TAGSET_DEFAULT = 16
    def ldefault():
        return {'match_len': Limits.MATCH_LEN_DEFAULT, 'ptr_depth_limit': Limits.PTR_DEPTH_LIMIT_DEFAULT, 'tags_per_tagset': Limits.TAGS_PER_TAGSET_DEFAULT}
    def lnew(match_len, ptr_depth_limit, tags_per_tagset, eval_field='NONE', eval_val=0):
        return {'eval_field': eval_field, 'eval_val': eval_val, 'match_len': match_len, 'ptr_depth_limit': ptr_depth_limit, 'tags_per_tagset': tags_per_tagset}
    def lmax(limits, max_match_len=float('inf'), max_ptr_depth_limit=float('inf')):
        return Limits.lnew(min(limits['match_len'], max_match_len),
                        min(limits['ptr_depth_limit'], max_ptr_depth_limit),
                        limits['tags_per_tagset'])
    def lset(limits, new_match_len=None, new_ptr_depth_limit=None):
            return Limits.lnew(limits['match_len'] if new_match_len==None else new_match_len,
                            limits['ptr_depth_limit'] if new_ptr_depth_limit==None else new_ptr_depth_limit,
                            limits['tags_per_tagset'])
    def liflow(arg_num, limit_field, limit_val):
        return 'has_arg' + str(arg_num) + '_iflow__' + limit_field + '__' + str(limit_val)
    def liflow_default(arg_num):
        return Limits.liflow(arg_num, 'match_len', Limits.MATCH_LEN_DEFAULT) # Could also use another field with its default value

init_django()

# So that yaml.dump() prints numbers in hex (https://stackoverflow.com/a/42504639)
def hexint_presenter(dumper, data):
    return dumper.represent_int(hex(data))
yaml.add_representer(int, hexint_presenter)

class Report(models.Model):
    syscall = models.CharField(max_length=30)
    report_num = models.BigIntegerField()
    pid = models.IntegerField()  # current pid
    ppid = models.IntegerField() # parent's pid
    tid = models.IntegerField()  # current tid
    ptid = models.IntegerField() # parent's tid
    tainted = models.BooleanField()
    application = models.CharField(max_length=50)
    application_testcase = models.CharField(max_length=100)
    application_corepath = models.FilePathField(path="/", recursive=True, max_length=150)
    application_corenum = models.IntegerField()
    backtrace = models.JSONField()

    class Meta:
        constraints = [models.UniqueConstraint(fields=['application_corepath', 'pid', 'ppid', 'tid', 'ptid', 'report_num'], name='unique report_nums per thread/process/core')]

    def __str__(self):
        return yaml.dump(model_to_dict(self), default_flow_style=True, width=20, indent=4, sort_keys=False)

    ################################

    syscall_nr_taint = models.JSONField()
    has_syscallnr_taint = models.BooleanField(null=True)

    ################################

    syscall_args = models.JSONField()

    has_arg0_taint = models.BooleanField(null=True)
    has_arg0_iflow = models.JSONField(null=True)
    arg0_iflows_list = models.JSONField(null=True)
    has_arg0_uflow = models.JSONField(null=True)
    arg0_done_uflow_eval = models.BooleanField(null=True)

    has_arg1_taint = models.BooleanField(null=True)
    has_arg1_iflow = models.JSONField(null=True)
    arg1_iflows_list = models.JSONField(null=True)
    has_arg1_uflow = models.JSONField(null=True)
    arg1_done_uflow_eval = models.BooleanField(null=True)

    has_arg2_taint = models.BooleanField(null=True)
    has_arg2_iflow = models.JSONField(null=True)
    arg2_iflows_list = models.JSONField(null=True)
    has_arg2_uflow = models.JSONField(null=True)
    arg2_done_uflow_eval = models.BooleanField(null=True)

    has_arg3_taint = models.BooleanField(null=True)
    has_arg3_iflow = models.JSONField(null=True)
    arg3_iflows_list = models.JSONField(null=True)
    has_arg3_uflow = models.JSONField(null=True)
    arg3_done_uflow_eval = models.BooleanField(null=True)

    has_arg4_taint = models.BooleanField(null=True)
    has_arg4_iflow = models.JSONField(null=True)
    arg4_iflows_list = models.JSONField(null=True)
    has_arg4_uflow = models.JSONField(null=True)
    arg4_done_uflow_eval = models.BooleanField(null=True)

    has_arg5_taint = models.BooleanField(null=True)
    has_arg5_iflow = models.JSONField(null=True)
    arg5_iflows_list = models.JSONField(null=True)
    has_arg5_uflow = models.JSONField(null=True)
    arg5_done_uflow_eval = models.BooleanField(null=True)

    done_analyzing = models.BooleanField()

    def get_taint(self, argnum):
        match argnum:
            case 0: return self.has_arg0_taint
            case 1: return self.has_arg1_taint
            case 2: return self.has_arg2_taint
            case 3: return self.has_arg3_taint
            case 4: return self.has_arg4_taint
            case 5: return self.has_arg5_taint
    def arg_taint(self, argnum, b):
        match argnum:
            case 0: self.has_arg0_taint = b
            case 1: self.has_arg1_taint = b
            case 2: self.has_arg2_taint = b
            case 3: self.has_arg3_taint = b
            case 4: self.has_arg4_taint = b
            case 5: self.has_arg5_taint = b

    def get_iflow(self, arg_num, limit_field='match_len', limit_val=Limits.MATCH_LEN_DEFAULT):
        match arg_num:
            case 0: return self.has_arg0_iflow[limit_field][limit_val]
            case 1: return self.has_arg1_iflow[limit_field][limit_val]
            case 2: return self.has_arg2_iflow[limit_field][limit_val]
            case 3: return self.has_arg3_iflow[limit_field][limit_val]
            case 4: return self.has_arg4_iflow[limit_field][limit_val]
            case 5: return self.has_arg5_iflow[limit_field][limit_val]
    def arg_iflow(self, argnum, b, limit_field, limit_val):
        match argnum:
            case 0: self.has_arg0_iflow[limit_field][limit_val] = b
            case 1: self.has_arg1_iflow[limit_field][limit_val] = b
            case 2: self.has_arg2_iflow[limit_field][limit_val] = b
            case 3: self.has_arg3_iflow[limit_field][limit_val] = b
            case 4: self.has_arg4_iflow[limit_field][limit_val] = b
            case 5: self.has_arg5_iflow[limit_field][limit_val] = b
    def arg_no_iflow(self, argnum):
        for i in range(0,Limits.MATCH_LEN_MAX+1): self.arg_iflow(argnum, False, 'match_len', i)
        for i in range(0,Limits.PTR_DEPTH_LIMIT_MAX+1): self.arg_iflow(argnum, False, 'ptr_depth_limit', i)
        for i in range(0,Limits.TAGS_PER_TAGSET_MAX+1): self.arg_iflow(argnum, False, 'tags_per_tagset', i)

    # Typical iflows list: [f1, f2, ...]
    # Chained iflows list: []
    # No iflows list:      None
    def get_iflows_list(self, arg_num):
        match arg_num:
            case 0: return self.arg0_iflows_list
            case 1: return self.arg1_iflows_list
            case 2: return self.arg2_iflows_list
            case 3: return self.arg3_iflows_list
            case 4: return self.arg4_iflows_list
            case 5: return self.arg5_iflows_list
    def set_iflows_list(self, arg_num, l):
        match arg_num:
            case 0: self.arg0_iflows_list = l
            case 1: self.arg1_iflows_list = l
            case 2: self.arg2_iflows_list = l
            case 3: self.arg3_iflows_list = l
            case 4: self.arg4_iflows_list = l
            case 5: self.arg5_iflows_list = l

    def get_uflow(self, arg_num):
        match arg_num:
            case 0: return self.has_arg0_uflow
            case 1: return self.has_arg1_uflow
            case 2: return self.has_arg2_uflow
            case 3: return self.has_arg3_uflow
            case 4: return self.has_arg4_uflow
            case 5: return self.has_arg5_uflow
    def set_uflow(self, arg_num, conf):
        match arg_num:
            case 0: self.has_arg0_uflow = conf
            case 1: self.has_arg1_uflow = conf
            case 2: self.has_arg2_uflow = conf
            case 3: self.has_arg3_uflow = conf
            case 4: self.has_arg4_uflow = conf
            case 5: self.has_arg5_uflow = conf

    def get_uflow_eval_done(self, arg_num):
        match arg_num:
            case 0: self.arg0_done_uflow_eval
            case 1: self.arg1_done_uflow_eval
            case 2: self.arg2_done_uflow_eval
            case 3: self.arg3_done_uflow_eval
            case 4: self.arg4_done_uflow_eval
    def set_uflow_eval_done(self, arg_num, b):
        match arg_num:
            case 0: self.arg0_done_uflow_eval = b
            case 1: self.arg1_done_uflow_eval = b
            case 2: self.arg2_done_uflow_eval = b
            case 3: self.arg3_done_uflow_eval = b
            case 4: self.arg4_done_uflow_eval = b
            case 5: self.arg5_done_uflow_eval = b

class RopReport(models.Model):
    operand_type = models.CharField(max_length=30)
    pid = models.IntegerField()  # current pid
    ppid = models.IntegerField() # parent's pid
    tid = models.IntegerField()  # current tid
    ptid = models.IntegerField() # parent's tid
    tainted = models.BooleanField()
    application = models.CharField(max_length=50)
    application_corepath = models.FilePathField(path="/", recursive=True, max_length=150)
    application_corenum = models.IntegerField()
    backtrace = models.JSONField()
    rip = models.BigIntegerField()

    target = models.JSONField()
    has_taint = models.BooleanField(null=True)
    has_iflow = models.BooleanField(null=True)

    done_analyzing = models.BooleanField()

    def __str__(self):
        return yaml.dump(model_to_dict(self), default_flow_style=True, width=20, indent=4, sort_keys=False)
