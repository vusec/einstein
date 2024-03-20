from db.models import Report, RopReport, Limits
from django.db.models import Q
from tqdm import tqdm
import json

def add_reports(reports_path):
    print("Loading reports from file '" + reports_path + "'...")
    with open(reports_path, "r") as stream:
        robjs = json.load(stream)
    limits_tbl = {'match_len': [None for i in range(Limits.MATCH_LEN_MAX+1)],
                  'ptr_depth_limit': [None for i in range(Limits.PTR_DEPTH_LIMIT_MAX+1)],
                  'tags_per_tagset': [None for i in range(Limits.TAGS_PER_TAGSET_MAX+1)]}
    Report.objects.bulk_create([Report(**robj,
                                       has_arg0_iflow=limits_tbl,
                                       has_arg1_iflow=limits_tbl,
                                       has_arg2_iflow=limits_tbl,
                                       has_arg3_iflow=limits_tbl,
                                       has_arg4_iflow=limits_tbl,
                                       has_arg5_iflow=limits_tbl,
                                       arg0_iflows_list=None,
                                       arg1_iflows_list=None,
                                       arg2_iflows_list=None,
                                       arg3_iflows_list=None,
                                       arg4_iflows_list=None,
                                       arg5_iflows_list=None,
                                       has_arg0_uflow=None,
                                       has_arg1_uflow=None,
                                       has_arg2_uflow=None,
                                       has_arg3_uflow=None,
                                       has_arg4_uflow=None,
                                       has_arg5_uflow=None,
                                       arg0_done_uflow_eval=False,
                                       arg1_done_uflow_eval=False,
                                       arg2_done_uflow_eval=False,
                                       arg3_done_uflow_eval=False,
                                       arg4_done_uflow_eval=False,
                                       arg5_done_uflow_eval=False,
                                       done_analyzing=False) for robj in tqdm(robjs, desc="Saving reports")], batch_size=10000)
    print("Done saving reports.")

def add_rop_reports(ropreports_path):
    print("Loading ROP reports from file '" + ropreports_path + "'...")
    with open(ropreports_path, "r") as stream:
        robjs = json.load(stream)
    RopReport.objects.bulk_create([RopReport(**robj,
                                             done_analyzing=False) for robj in tqdm(robjs, desc="Saving ROP reports")], batch_size=10000)
    print("Done saving ROP reports.")
