#!/usr/bin/env python3

from db.add import add_reports, add_rop_reports
from db.analyze import analyze_reports, analyze_rop_reports
from db.custom import custom
from db.output import print_graphs, print_candidates, print_exploits, print_rop_candidates
from db.rewrite import rewrite_eval
import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process Einstein reports.')
    parser.add_argument('action', choices=['add_reports', 'add_rop_reports',
                                           'analyze_reports', 'analyze_rop_reports', 'analyze_candidates',
                                           'print_candidates', 'print_rop_candidates', 'print_exploits',
                                           'print_graphs', 'custom'],
                        help='action to perform')
    parser.add_argument('--json_path', metavar='jpath', help="the path to the JSON file")
    parser.add_argument('--root_path', metavar='rpath', help="the path to repository's root directory")
    parser.add_argument('--nproc', metavar='nproc', type=int, help="the number of processes to spawn")
    args = parser.parse_args()
    if (args.action == 'add_reports' or args.action == 'add_rop_reports') and args.json_path is None:
        parser.error("Argument --json_path is required.")
    if args.action == 'analyze_candidates' and args.root_path is None:
        parser.error("Argument --root_path is required.")
    if args.action == 'analyze_reports' and args.nproc is None or args.action == 'analyze_rop_reports' and args.nproc is None:
        parser.error("Argument --nproc is required.")

    match args.action:
        case 'add_reports': add_reports(args.json_path)
        case 'add_rop_reports': add_rop_reports(args.json_path)
        case 'analyze_reports': analyze_reports(args.nproc)
        case 'analyze_rop_reports': analyze_rop_reports(args.nproc)
        case 'analyze_candidates': rewrite_eval(args.root_path)
        case 'print_candidates': print_candidates()
        case 'print_rop_candidates': print_rop_candidates()
        case 'print_exploits': print_exploits()
        case 'print_graphs': print_graphs()
        case 'custom': custom()