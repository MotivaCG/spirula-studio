// Prints a .mint chunk table and dumps decoded frames at given instants.
#include "mintfile.h"
#include <QCoreApplication>
#include <QFile>
#include <cstdio>

int main(int argc, char** argv)
{
    QCoreApplication app(argc, argv);
    const QStringList args = app.arguments();
    if (args.size() < 3) {
        std::fprintf(stderr, "usage: mintprobe <file.mint> <outprefix> [seconds...]\n");
        return 2;
    }
    MintFile mint;
    QString error;
    if (!mint.open(args[1], &error)) {
        std::fprintf(stderr, "%s\n", qPrintable(error));
        return 1;
    }
    std::printf("duration %.6f frames %d chunks %d\n", mint.duration(), mint.frameCount(),
                int(mint.chunks().size()));
    for (const MintChunk& chunk : mint.chunks()) {
        std::printf("chunk %d start %.6f duration %.6f", chunk.index, chunk.start, chunk.duration);
        for (const MintBlock& block : chunk.blocks)
            if (block.type == 1)
                std::printf("  [g int=%llu splats=%llu mesh=%llu ps=%d rs=%d]",
                            block.intervals, block.splats, block.meshSamples,
                            int(block.positionPerSample), int(block.rotationPerSample));
        std::printf("\n");
    }
    for (int a = 3; a < args.size(); ++a) {
        const double t = args[a].toDouble();
        MintFrame frame;
        if (!mint.decode(t, &frame, true, &error)) {
            std::fprintf(stderr, "t=%s: %s\n", qPrintable(args[a]), qPrintable(error));
            return 1;
        }
        QFile file(args[2] + "_" + args[a] + ".bin");
        if (!file.open(QIODevice::WriteOnly))
            return 1;
        const quint64 n = frame.count;
        file.write(reinterpret_cast<const char*>(&n), 8);
        auto put = [&](const QVector<float>& v) {
            file.write(reinterpret_cast<const char*>(v.constData()), v.size() * sizeof(float));
        };
        put(frame.position);
        put(frame.scale);
        put(frame.opacity);
        put(frame.colorDc);
        put(frame.rotation);
        file.write(reinterpret_cast<const char*>(frame.active.constData()), frame.active.size());
        put(frame.shRest);
        std::printf("t=%s chunk %d sample %d alpha %.4f count %llu\n", qPrintable(args[a]),
                    frame.chunkIndex, frame.sampleIndex, frame.sampleAlpha, n);
    }
    return 0;
}
