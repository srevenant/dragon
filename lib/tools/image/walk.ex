defmodule Dragon.Tools.Image.Walk do
  @moduledoc """
  walk a tree and convert images it finds
  """

  # # origsuffix = files[file]['suffix']
  # # ofile = f"{file}.{info['suffix']}"
  # #src = os.path.join(info['dir'], ofile)
  # #dst = os.path.join(info['dir'], file)
  # #(maxw, maxh) = getsize(src)
  #
  # if maxw not in args.no_resolution:
  #     for suffix in types:
  #         new = f"{dst}.{suffix}"
  #         if not os.path.exists(new) or (suffix != origsuffix and args.force):
  #             print(f"{file}.{origsuffix} -> {suffix}")
  #             refit(src, new)
  #         link = f"{dst}-x{maxw}.{suffix}"
  #         if not os.path.exists(link):
  #             olink = f"{file}.{suffix}"
  #             print(f"{link} @-> {olink}")
  #             os.symlink(olink, link)
  #
  # sizes = dict()
  # for res in resolutions:
  #     if res > maxw:
  #         print(f"{file} not upscaling to {res}")
  #     else:
  #         new = f"{dst}-x{res}"
  #
  #         for suffix in types:
  #             nnew = f"{new}.{suffix}"
  #             if not os.path.exists(nnew) or args.force:
  #                 print(f"{file} [{maxw}] -> -x{res}.{suffix}")
  #                 refit(src, nnew, "-resize", res)
  #
  #         (w, h) = getsize(f"{new}.{types[0]}")
  #         sizes[w] = h
  #
  # if maxw not in args.no_resolution:
  #     sizes[maxw] = maxh
  #
  # sizes = [{k: sizes[k]} for k in list(sorted(sizes.keys()))]
  #
  # update_img_spec(cfg, id=file, base=f"/{info['dir']}", sizes=sizes, types=types)
end

# #!/usr/bin/env python3
#
# TYPES = ["jpg", "webp", "png"]
# RESOLUTIONS = [200, 480, 1440, 1920]
# # TODO: don't link to anything bigger than this
# #MAXWIDTH = 2000
# SIZEREX = re.compile("-x[0-9]+(?=\.|-|$)")
# ARTCFG = "_data/common/media.yml"
#
# ################################################################################
# def main():
#     if not os.path.exists(os.path.basename(sys.argv[0])):
#         sys.exit("Must be run from root of project")
#
#     cmd = argparse.ArgumentParser()
#     cmd.add_argument('--force', '-f', action='store_true')
#     cmd.add_argument('--config', '-c', action='store_true')
#     cmd.add_argument('--types', '-t', action='store', default=TYPES)
#     cmd.add_argument('--resolutions', '-r', action='store', default=RESOLUTIONS)
#     cmd.add_argument('--no-resolution', '-xr', action='store', default=[])
#     cmd.add_argument('--no-type', '-xt', action='store', default=[])
#     cmd.add_argument('files', nargs='+')
#     args = cmd.parse_args()
#
#     resolutions = list(args.resolutions)
#     if args.no_resolution:
#         args.no_resolution = [int(res) for res in args.no_resolution.split(",")]
#         for res in args.no_resolution:
#             if res in resolutions:
#                 resolutions.remove(int(res))
#
#     types = list(args.types)
#     if args.no_type:
#         args.no_type = args.no_type.split(",")
#         for type in args.no_type:
#             if type in types:
#                 types.remove(type)
#
#     cfg = {}
#     if args.config:
#         # sanity check
#         with open(ARTCFG) as infile:
#             cfg = yaml.safe_load(infile)
#         if not cfg:
#             sys.exit("Cannot find config?")
#
#     files = {}
#     for f in args.files:
#         dir = os.path.dirname(f)
#         base = os.path.basename(f)
#         split = base.split(".")
#         if len(split) != 2:
#             continue
#         [file, suffix] = split
#         if suffix not in types:
#             continue
#         file = SIZEREX.sub("", file)
#         # preference for png
#         current = files.get(file)
#         if not current or current['suffix'] != "png":
#             files[file] = {"suffix": suffix, "dir": dir}
#
#     # base image first
#     for file, info in files.items():
#         origsuffix = files[file]['suffix']
#         ofile = f"{file}.{info['suffix']}"
#         src = os.path.join(info['dir'], ofile)
#         dst = os.path.join(info['dir'], file)
#         (maxw, maxh) = getsize(src)
#         if maxw not in args.no_resolution:
#             sys.stdout.flush()
#             for suffix in types:
#                 new = f"{dst}.{suffix}"
#                 if not os.path.exists(new) or (suffix != origsuffix and args.force):
#                     print(f"{file}.{origsuffix} -> {suffix}")
#                     refit(src, new)
#                 link = f"{dst}-x{maxw}.{suffix}"
#                 if not os.path.exists(link):
#                     olink = f"{file}.{suffix}"
#                     print(f"{link} @-> {olink}")
#                     os.symlink(olink, link)
#
#         sizes = dict()
#         for res in resolutions:
#             if res > maxw:
#                 print(f"{file} not upscaling to {res}")
#             else:
#                 new = f"{dst}-x{res}"
#
#                 for suffix in types:
#                     nnew = f"{new}.{suffix}"
#                     if not os.path.exists(nnew) or args.force:
#                         print(f"{file} [{maxw}] -> -x{res}.{suffix}")
#                         refit(src, nnew, "-resize", res)
#
#                 (w, h) = getsize(f"{new}.{types[0]}")
#                 sizes[w] = h
#
#         if maxw not in args.no_resolution:
#             sizes[maxw] = maxh
#
#         sizes = [{k: sizes[k]} for k in list(sorted(sizes.keys()))]
#
#         update_img_spec(cfg, id=file, base=f"/{info['dir']}", sizes=sizes, types=types)
#
#     if args.config:
#         # shutil.copyfile(ARTCFG, f"{ARTCFG}.bak")
#         with open(f"{ARTCFG}2.yml", "w") as outfile:
#             outfile.write(yaml.dump(cfg, Dumper=NoAliasDumper))
